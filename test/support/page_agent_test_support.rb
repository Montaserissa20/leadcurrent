require_relative "ai_test_support"

module PageAgentTestSupport
  class CopilotResponse < AiTestSupport::Response
    def initialize(code,body,headers={})
      super(code,body)
      @headers=headers
    end
    def [](key) = @headers[key]
  end
  def agent_body(task = "Find my overdue leads.")
    { "model" => PageAgent::Protocol::MODEL, "messages" => [{ "role" => "system", "content" => "client instructions" }, { "role" => "user", "content" => task }],
      "tools" => [{ "type" => "function", "function" => { "name" => "AgentOutput", "parameters" => {} } }], "parallel_tool_calls" => false,
      "tool_choice" => { "type" => "function", "function" => { "name" => "AgentOutput" } } }
  end
  def install_agent_fake
    @previous_agent_env = ENV.to_h.slice("GROQ_API_KEY", "LEADCURRENT_LIVE_AGENT")
    @previous_agent_factory = PageAgent::GroqClient.http_factory
    @agent_key = SecureRandom.hex(24)
    ENV["GROQ_API_KEY"] = @agent_key
    ENV.delete("LEADCURRENT_LIVE_AGENT")
    @agent_requests = []
    @copilot_requests = []
    @copilot_plan = nil
    @agent_steps = []
    @agent_status = 200
    @agent_delay = 0
    @agent_http = AiTestSupport::Http.new do |request|
      raise @agent_exception if @agent_exception
      @agent_authorization = request["Authorization"]
      payload = JSON.parse(request.body)
      if payload.dig('response_format','json_schema','name') == 'copilot_intent'
        @copilot_requests << payload
        sleep @agent_delay if @agent_delay.positive?
        plan = @copilot_plan || copilot_plan
        raw = @copilot_raw || JSON.generate(model:PageAgent::Protocol::MODEL,choices:[{finish_reason:'stop',message:{role:'assistant',content:JSON.generate(plan)}}],usage:{prompt_tokens:100,completion_tokens:30,total_tokens:130})
        status=@copilot_statuses&.shift || @copilot_status || @agent_status
        next CopilotResponse.new(status,raw,status == 429 && @copilot_retry_after ? {'retry-after'=>@copilot_retry_after.to_s} : {})
      end
      @agent_requests << payload
      sleep @agent_delay if @agent_delay.positive?
      action = @agent_action
      if !action && @agent_steps.any?
        name, label, text = @agent_steps.shift
        if name == "done"
          action = { "done" => { "text" => label, "success" => true } }
        else
          # Fixture resolves target tokens from the REAL PageController observation.
          # It never navigates the browser or executes routes itself.
          observation = payload["messages"].last["content"].split("<browser_state>").last
          line = observation.lines.find { |item| item.start_with?("control_") && item.include?(label) }
          unless line
            File.write(Rails.root.join('.local','agent-fixture-failure.json'),JSON.pretty_generate(expected:label,observation:observation))
            raise "Fixture could not find the requested visible control: #{label}"
          end
          args = { "target" => line.split.first }
          if name == 'apply_filters'
            args['fields']=text.map do |field_label,value|
              field_line=observation.lines.find{|item|item.start_with?('control_')&&item.include?(field_label)}
              raise "Fixture could not find a visible batch field" unless field_line
              {'target'=>field_line.split.first,'text'=>value}
            end
          else
            args["text"] = text if text
          end
          action = { name => args }
        end
      end
      action ||= { "done" => { "text" => "Read-only task finished.", "success" => true } }
      arguments = @agent_arguments || { "action" => action }
      raw = @agent_raw || JSON.generate(model: PageAgent::Protocol::MODEL, choices: [{ finish_reason: "tool_calls", message: { role: "assistant", content: nil,
        tool_calls: [{ id: "call_fixture", type: "function", function: { name: "AgentOutput", arguments: JSON.generate(arguments) } }] } }], usage: { prompt_tokens: 100, completion_tokens: 30, total_tokens: 130 })
      AiTestSupport::Response.new(@agent_status, raw)
    end
    PageAgent::GroqClient.http_factory = ->(_uri) { @agent_http }
    PageAgent::RequestGate::STORE.clear
    PageAgent::RequestGate::MUTEX.synchronize { PageAgent::RequestGate::IN_FLIGHT.clear }
  end
  def copilot_plan(**overrides)
    plan={ 'intent'=>'answer_question','query'=>'none','audience'=>'workspace','status'=>'any','period'=>'all','destination'=>'none','help_link'=>'none','answer'=>'LeadCurrent helps you manage leads, opportunities and follow-up tasks.','search'=>'','action_task'=>'','navigate'=>false }.merge(overrides.transform_keys(&:to_s))
    navigate=plan.delete('navigate')
    plan['intent']='show_crm_data' if plan['intent']=='read_crm_data' && navigate
    plan
  end
  def restore_agent_fake
    PageAgent::GroqClient.http_factory = @previous_agent_factory
    %w[GROQ_API_KEY LEADCURRENT_LIVE_AGENT].each { |key| @previous_agent_env.key?(key) ? ENV[key] = @previous_agent_env[key] : ENV.delete(key) }
    PageAgent::RequestGate::STORE.clear
    PageAgent::RequestGate::MUTEX.synchronize { PageAgent::RequestGate::IN_FLIGHT.clear }
  end
end
