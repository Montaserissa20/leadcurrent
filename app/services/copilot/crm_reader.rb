module Copilot
  class CrmReader
    include Rails.application.routes.url_helpers
    LIMIT = 10
    def initialize(user, plan)
      @user, @plan = user, plan
    end

    def call
      Planner.validate_query!(@plan)
      case @plan.fetch("query")
      when "team_summary"
        team_summary
      when "leads", "uncontacted_leads"
        records = search(scope(Lead))
        records = records.awaiting_contact.where.not(status:%w[converted disqualified]) if @plan['query'] == 'uncontacted_leads'
        records = stage(records)
        list(records.order(:first_contact_deadline,:id),"#{@plan['status'] == 'any' ? '' : @plan['status']+' '}#{@plan['query'] == 'uncontacted_leads' ? 'uncontacted ' : ''}leads") { |lead| record_row(lead).merge(deadline:time(lead.first_contact_deadline)) }
      when "overdue_leads", "attention_leads"
        records = scope(Lead).awaiting_contact.where.not(status:%w[converted disqualified])
        records = @plan["query"] == "overdue_leads" ? records.overdue : records.where("first_contact_deadline <= ?",Time.current.in_time_zone(@user.time_zone).end_of_day)
        records = search(records).order(:first_contact_deadline,:id)
        result = list(records,"#{@plan['query'] == 'overdue_leads' ? 'overdue leads' : 'leads needing first contact by end of today'}") { |lead| record_row(lead).merge(deadline:time(lead.first_contact_deadline)) }
        add_overdue_recommendation(result,records) if @plan['query'] == 'overdue_leads'
        result
      when "pending_tasks"
        records = scope(Task).pending
        records = records.where(due_at:Time.current.in_time_zone(@user.time_zone).all_day) if @plan["period"] == "today"
        records = records.overdue if @plan["period"] == "overdue"
        records = records.where("title ILIKE ?",term) if @plan["search"].present?
        list(records.order(:due_at,:id),"#{@plan['period'] == 'all' ? '' : @plan['period']+' '}pending follow-ups") do |task|
          record_row(task.record).merge(title:clean(task.title),deadline:time(task.due_at),status:"Pending")
        end
      when "opportunities"
        records = search(scope(Opportunity))
        records = records.where(status:@plan["status"]) unless @plan["status"] == "any"
        list(records.order(:expected_closing_date,:id),"#{@plan['status'] == 'any' ? '' : @plan['status']+' '}opportunities") { |deal| record_row(deal).merge(deadline:deal.expected_closing_date.iso8601) }
      when "opportunity_summary"
        opportunity_summary
      when "inactive_opportunities"
        records = search(scope(Opportunity)).active.where('last_activity_at <= ?',Time.current - NextBestAction::INACTIVITY_WINDOW)
        list(records.order(:last_activity_at,:id),'inactive opportunities') { |deal| record_row(deal).merge(detail:"Last recorded activity: #{time(deal.last_activity_at)}") }
      when "customer_summary"
        customer_summary
      when "lead_status"
        counts = stage(search(scope(Lead))).group(:status).count
        {kind:"verified_crm",count:counts.values.sum,counts:counts,answer:"Lead status breakdown for #{audience} (#{counts.values.sum} leads).",records:counts.sort.map { |status,count| {title:status.humanize,detail:count.to_s,path:leads_path(status:status,owner_id:mine? ? @user.id : nil)} },as_of:Time.current.iso8601}
      when "next_best_action"
        # The official service already bounds and orders its candidates. For a narrower
        # owner/search subset, ask it about each bounded candidate instead of filtering
        # an already-truncated global top-eight list (which could hide every match).
        if mine? && @user.manager? || @plan['search'].present?
          leads = search(scope(Lead)).awaiting_contact.where.not(status:%w[converted disqualified]).order(:first_contact_deadline,:id).limit(8)
          deals = search(scope(Opportunity)).active.order(:last_activity_at,:id).limit(8)
          entries = (leads.to_a+deals.to_a).flat_map { |record| NextBestAction.new(@user).call(record:record,limit:1) }.sort_by { |entry| -entry.priority }.first(8)
        else
          entries = NextBestAction.new(@user).call(limit:8)
        end
        # The official service intentionally limits recommendations to editable owners, even for readers.
        recommendations(entries)
      else
        raise PageAgent::Error.new(:invalid_request)
      end
    rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished, ActiveRecord::RecordNotFound
      raise PageAgent::Error.new(:unverified)
    end

    private
    def add_overdue_recommendation(result,records)
      eligible = @user.manager? ? records : records.where(owner_id:@user.id)
      lead = eligible.first # Same earliest-deadline/id order as the official overdue-contact candidates.
      entry = lead && NextBestAction.new(@user).call(record:lead,limit:1).first
      return unless entry
      row = record_row(entry.record).merge(priority:entry.priority,detail:"Priority #{entry.priority}: #{entry.reason}")
      result[:recommendation] = row
      result[:answer] += " First eligible contact for you: #{row[:title]} at #{row[:company]}. Official Next Best Action priority #{entry.priority}: #{entry.reason}."
      if (listed=result[:records].find{|record|record[:path]==row[:path]})
        listed.merge!(row)
      else
        result[:links] = [row.merge(title:"Recommended first: #{row[:title]}")]
      end
    end
    def team_summary
      # Settings' roster is readable by both roles; adding users remains manager-only.
      counts = WorkspaceAccess.scope(@user,User).group(:role).count
      total = counts.values.sum
      included = WorkspaceAccess.scope(@user,User).exists?(id:@user.id)
      membership = included ? 'including you' : 'not including you (no registered membership found)'
      selected = @plan['status'] == 'any' ? total : counts.fetch(@plan['status'],0)
      managers, salespeople = counts.fetch('manager',0), counts.fetch('salesperson',0)
      answer = "Your workspace has #{total} registered #{total == 1 ? 'user' : 'users'}, #{membership}: #{managers} #{managers == 1 ? 'manager' : 'managers'} and #{salespeople} #{salespeople == 1 ? 'salesperson' : 'salespeople'}."
      answer += " Registered #{@plan['status'] == 'salesperson' ? 'salespeople' : 'managers'}: #{selected}." unless @plan['status'] == 'any'
      {kind:'verified_crm',count:selected,total:total,counts:counts,includes_current_user:included,answer:answer+' This is registered membership; online status is unknown.',records:[],as_of:Time.current.iso8601}
    end
    def stage(records) = @plan['status'] == 'any' ? records : records.where(status:@plan['status'])
    def opportunity_summary
      records = stage(search(scope(Opportunity)))
      counts = records.group(:status).count
      values = records.active.group(:currency).sum(:value).transform_values { |value| value.to_s('F') }
      rows = counts.sort.map { |status,count| {title:status.humanize,detail:"#{count} opportunities"} }
      rows += values.sort.map { |currency,value| {title:"#{currency} active pipeline",detail:"#{value} #{currency}"} }
      {kind:'verified_crm',count:counts.values.sum,counts:counts,pipeline_values:values,answer:"#{counts.values.sum} opportunities for #{audience}; #{counts.except('won','lost').values.sum} are active. Pipeline values below exclude Won/Lost and keep each currency separate; no exchange conversion is assumed.",records:rows,as_of:Time.current.iso8601}
    end
    def customer_summary
      leads = search(scope(Lead))
      deals = search(scope(Opportunity))
      count = leads.count+deals.count
      rows = leads.order(:id).includes(:company).limit(LIMIT).map { |record| record_row(record).merge(detail:'Lead') }
      rows += deals.order(:id).includes(:company).limit(LIMIT-rows.size).map { |record| record_row(record).merge(detail:'Opportunity') }
      {kind:'verified_crm',count:count,answer:count.zero? ? "No matching customer records for #{audience}." : "#{count} matching lead/opportunity records for #{audience}. Showing up to #{LIMIT}; a converted lead and its opportunity are separate records, not two customers.",records:rows,as_of:Time.current.iso8601}
    end
    def recommendations(entries,subset=nil)
      text = entries.empty? ? "No eligible Next Best Action recommendations are available for you." : "Here are #{entries.size} official Next Best Action recommendations for you, highest priority first (up to 8)."
      text += " Scope: #{subset} for #{audience}; only records you can act on." if subset
      {kind:'verified_crm',count:entries.size,answer:text,records:entries.map { |entry| record_row(entry.record).merge(detail:"Priority #{entry.priority}: #{entry.reason}",priority:entry.priority) },as_of:Time.current.iso8601}
    end
    def mine? = @plan["audience"] == "mine"
    def audience = mine? ? "your records" : "this workspace"
    def scope(model)
      relation = WorkspaceAccess.scope(@user,model)
      mine? ? relation.where(owner_id:@user.id) : relation
    end
    def term = "%#{ActiveRecord::Base.sanitize_sql_like(@plan['search'])}%"
    def search(records)
      return records if @plan["search"].blank?
      records.where("title ILIKE ?",term).or(records.where(company_id:WorkspaceAccess.scope(@user,Company).where("name ILIKE ?",term).select(:id)))
    end
    def list(records,label)
      count = records.count
      loaded = records.klass == Task ? records.includes(lead: :company,opportunity: :company) : records.includes(:company)
      rows = loaded.limit(LIMIT).map { |record| yield(record) }
      display_label = count == 1 ? label.strip.singularize : label.strip
      answer = count.zero? ? "I found no #{label.strip} for #{audience}." : "I found #{count} #{display_label} for #{audience}."
      answer += " Showing the first #{rows.size}; the list is limited to #{LIMIT}." if count > LIMIT
      {kind:"verified_crm",answer:answer,count:count,records:rows,as_of:Time.current.iso8601}
    end
    def record_row(record)
      # Re-scope even associated task/NBA targets before exposing a link.
      record = WorkspaceAccess.scope(@user,record.class).find(record.id)
      company = WorkspaceAccess.scope(@user,Company).find(record.company_id)
      {title:clean(record.title),company:clean(company.name),status:record.status.humanize,path:record.is_a?(Lead) ? lead_path(record) : opportunity_path(record)}
    end
    def clean(text) = Ai::SafeText.call(text,limit:500)
    def time(value) = value.in_time_zone(@user.time_zone).strftime("%d %b %Y %H:%M %Z")
  end
end
