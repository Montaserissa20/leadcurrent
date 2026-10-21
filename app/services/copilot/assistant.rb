module Copilot
  class Assistant
    HELP_LINKS = {"leads"=>["Open Leads","/leads"],"new_lead"=>["Create a lead manually","/leads/new"],"tasks"=>["Open Tasks","/tasks"],"pipeline"=>["Open Pipeline","/pipeline"],"analytics"=>["Open Analytics","/analytics"],"password"=>["Security & Password","/settings/password"]}.freeze
    def initialize(user,session_id,conversation_id=nil)
      @user = user
      @conversation = Conversation.new(user,session_id,conversation_id)
    end
    def call(message:,page_path:)
      page_record = Outcome.authorize_page!(@user,page_path)
      raise PageAgent::Error.new(:invalid_request) unless message.is_a?(String) && message.length.between?(1,600) && message.strip.present?
      plan = PageAgent::RequestGate.call(@user) { Planner.new.call(question:message,history:@conversation.history,page_path:page_path) }
      @conversation.remember(message,plan)
      if %w[read_crm_data show_crm_data].include?(plan["intent"])
        result = CrmReader.new(@user,plan).call
        # These summaries have no exact matching filter in the current UI; answer accurately without pretending.
        return envelope(result) if result[:count] == 0 || !plan["navigate"] || !%w[leads overdue_leads pending_tasks opportunities].include?(plan["query"])
        plan["destination"] = {"leads"=>"leads","overdue_leads"=>"leads","pending_tasks"=>"tasks","opportunities"=>"opportunities"}.fetch(plan["query"])
        # Render the model-selected query as an ordinary instruction, not a privileged URL/click shortcut.
        # The official Page Agent must still observe and choose real visible controls.
        owner = plan['audience'] == 'mine' ? 'Me' : 'All owners'
        filter = case plan['query']
        when 'overdue_leads' then 'First contact=Overdue and Status=All stages'
        when 'leads' then "First contact=Any deadline and Status=#{plan['status'] == 'any' ? 'All stages' : plan['status'].humanize}"
        when 'pending_tasks' then "Task status=#{plan['period'] == 'all' ? 'Pending' : plan['period'].capitalize}"
        when 'opportunities' then "Status=#{plan['status'] == 'any' ? 'All stages' : plan['status'].humanize}"
        end
        search_instruction = plan['search'].present? ? "Set Search to #{plan['search'].to_json}." : 'Search must be empty; clear it only if nonempty.'
        plan['action_task'] = "Open #{plan['destination']}. Required filters: Owner=#{owner}, #{filter}. #{search_instruction} Change only fields that differ. Apply all filters once. Leave the matching filtered list open, then finish."
      elsif plan["intent"] != "page_action"
        kind = {"answer_question"=>"guide","clarify"=>"clarification","unsupported_action"=>"safety"}.fetch(plan["intent"])
        links = HELP_LINKS[plan["help_link"]]
        return envelope(kind:kind,answer:plan["answer"],records:[],links:links ? [{title:links[0],path:links[1]}] : [])
      end
      if plan['intent'] == 'page_action' && plan['destination'] == 'record'
        # Resolve the permitted record TYPE, not a privileged navigation shortcut.
        # Do not spend DOM steps searching an unrelated, currently filtered list.
        result = CrmReader.new(@user,plan.merge('query'=>'customer_summary','status'=>'any','period'=>'all')).call
        return envelope(result) if result[:count] == 0
        candidates = result[:records].reject { |row| row[:detail] == 'Lead' && row[:status] == 'Converted' }
        if result[:count] > CrmReader::LIMIT || candidates.size != 1
          return envelope(result.merge(kind:'clarification',answer:'More than one matching customer record is available. Which linked lead or opportunity should I open? You can also ask using its exact title.'))
        end
        list = candidates.first[:detail] == 'Lead' ? 'Leads' : 'Opportunities'
        plan['action_task'] = "Open the #{list} list FIRST using its visible navigation link, unless the requested matching customer profile is already open. Find and open the customer matching #{plan['search'].to_json} there. Clear unrelated search/stage filters if necessary. Do not search the other record list. Use actual visible GET controls and open the matching record; never submit CRM writes."
      end
      if plan["destination"] == "note" && !page_path.match?(%r{\A/(leads|opportunities)/\d+\z})
        return envelope(kind:"clarification",answer:"Which customer should the note be for? Open an editable customer record first; I can prepare an unsaved note for your review.",records:[])
      end
      if plan['destination'] == 'note'
        begin
          WorkspaceAccess.authorize!(@user,page_record)
        rescue WorkflowError
          return envelope(kind:'safety',answer:'You can read this customer, but only its owner or a workspace manager can prepare an activity in its form. Ask the owner to review the follow-up.',records:[])
        end
        terminal = page_record.is_a?(Lead) ? page_record.status.in?(%w[converted disqualified]) : page_record.terminal?
        return envelope(kind:'safety',answer:'This record is closed, so a new activity cannot be prepared here. You can review its history or open an active customer you are allowed to edit.',records:[]) if terminal
      end
      if plan["action_task"].blank?
        return envelope(kind:"clarification",answer:"Would you like the matching records here, or should I also open and filter the CRM page?",records:[])
      end
      plan['initial_page'] = page_path
      envelope((result || {kind:"working",answer:"I’m checking the requested page using its visible controls.",records:[]}).merge(action:{run_id:@conversation.pending(plan),task:plan["action_task"]}))
    end

    def finish(input)
      plan = @conversation.consume(input["run_id"])
      verified = Outcome.verified?(@user,plan,input)
      result = if %w[read_crm_data show_crm_data].include?(plan["intent"])
        CrmReader.new(@user,plan).call
      elsif verified && plan["destination"] == "record"
        record = Outcome.authorize_page!(@user,input["page_path"])
        company = WorkspaceAccess.scope(@user,Company).find(record.company_id)
        name = "#{Ai::SafeText.call(record.title,limit:400)} at #{Ai::SafeText.call(company.name,limit:400)}"
        {kind:"verified_page",answer:plan['initial_page'] == input['page_path'] ? "#{name} is open." : "Opened #{name}.",records:[]}
      elsif verified && plan["destination"] == "note"
        {kind:"browser_observation",answer:"An unsaved note is present in the form. Review its wording and click Save action yourself if you approve. No contact, status change or task was submitted by the Copilot.",records:[]}
      elsif verified
        text = plan['initial_page'] == input['page_path'] ? "#{plan['destination'].humanize} is open." : "Opened #{plan['destination'].humanize}."
        {kind:"verified_page",answer:text+" You can continue here or ask another question.",records:[]}
      else
        {kind:"unverified",answer:"I couldn’t verify the requested page action. Try again or ask for the manual steps; no changes were submitted.",records:[]}
      end
      result[:answer] += verified ? " The requested filtered page is open." : " I couldn’t verify that the requested page filters were applied." if %w[read_crm_data show_crm_data].include?(plan["intent"])
      envelope(result.merge(verified:verified))
    end

    private
    def envelope(result) = result.merge(conversation_id:@conversation.id)
  end
end
