require "net/http"
require "json"
require "timeout"

module PageAgent
  class GroqClient
    ENDPOINT = URI("https://api.groq.com/openai/v1/chat/completions").freeze
    MAX_RESPONSE_BYTES = 24_576
    class_attribute :http_factory, default: ->(uri) { Net::HTTP.new(uri.host, uri.port) }, instance_writer: false

    def call(body, done_allowed: true, completion_only: false)
      data = exchange(Protocol.request!(body,done_allowed:done_allowed,completion_only:completion_only))
      choice, message = assistant!(data)
      raise Error.new(:invalid_response) unless %w[tool_calls stop].include?(choice["finish_reason"]) && message["tool_calls"].is_a?(Array) && message["tool_calls"].size == 1
      call = message["tool_calls"].first
      raise Error.new(:invalid_response) unless call.is_a?(Hash) && call["id"].is_a?(String) && call["id"].match?(/\A[a-zA-Z0-9_-]{1,100}\z/) && call["type"] == "function" && call.dig("function", "name") == "AgentOutput" && call.dig("function", "arguments").is_a?(String)
      arguments = Protocol.arguments!(JSON.parse(call["function"]["arguments"]))
      raise Error.new(:invalid_response) if !done_allowed && arguments['action'].key?('done')
      raise Error.new(:invalid_response) if completion_only && !arguments['action'].key?('done')
      usage = usage(data)
      ActiveSupport::Notifications.instrument("completion.page_agent", model: Protocol::MODEL, usage: usage, action: arguments["action"].keys.first, duration_seconds: @duration)
      { id: "page-agent-completion", object: "chat.completion", model: Protocol::MODEL, choices: [{ index: 0, finish_reason: "tool_calls", message: { role: "assistant", content: nil,
        tool_calls: [{ id: call["id"], type: "function", function: { name: "AgentOutput", arguments: JSON.generate(arguments) } }] } }], usage: usage }
    rescue PageAgent::Error => error
      invalid_diagnostic(data) if error.code == :invalid_response
      raise
    rescue JSON::ParserError, TypeError, NoMethodError
      invalid_diagnostic(data)
      raise Error.new(:invalid_response)
    end

    # Server-owned structured conversation protocol; never browser-selected model/URL/schema options.
    def plan(messages:, schema:)
      raise Error.new(:context_limit) if messages.sum { |m| m.fetch(:content).bytesize } > 12_000
      data = exchange(model: Protocol::MODEL, messages: messages, stream: false, tool_choice: "none", temperature: 0, reasoning_effort: "low", max_completion_tokens: 600,
        response_format: {type: "json_schema", json_schema: {name: "copilot_intent", strict: true, schema: schema}})
      choice, message = assistant!(data)
      raise Error.new(:invalid_response) unless choice["finish_reason"] == "stop" && message["tool_calls"].blank? && message["content"].is_a?(String)
      result = JSON.parse(message["content"])
      ActiveSupport::Notifications.instrument("completion.copilot", model: Protocol::MODEL, usage: usage(data), duration_seconds: @duration)
      result
    rescue JSON::ParserError, TypeError, NoMethodError
      raise Error.new(:invalid_response)
    end

    private
    def invalid_diagnostic(data)
      choice=data.is_a?(Hash) && data['choices'].is_a?(Array) && data['choices'].first
      message=choice.is_a?(Hash) && choice['message']
      call=message.is_a?(Hash) && message['tool_calls'].is_a?(Array) && message['tool_calls'].first
      function=call.is_a?(Hash) && call['function'].is_a?(Hash) ? call['function'] : nil
      arguments = function && function['arguments'].is_a?(String) ? (JSON.parse(function['arguments']) rescue nil) : nil
      action=arguments.is_a?(Hash) && arguments['action'].is_a?(Hash) && arguments['action'].keys.first
      action='unrecognized' unless Protocol::ACTIONS.key?(action)
      batch=arguments.is_a?(Hash) && arguments['action'].is_a?(Hash) ? arguments['action']['apply_filters'] : nil
      fields=batch.is_a?(Hash) ? batch['fields'] : nil
      reason=choice.is_a?(Hash) && %w[stop tool_calls length content_filter].include?(choice['finish_reason']) ? choice['finish_reason'] : 'other'
      ActiveSupport::Notifications.instrument('invalid_completion.page_agent',finish_reason:reason,action:action,field_count:fields.is_a?(Array) ? fields.size : nil,usage:data.is_a?(Hash) ? usage(data) : {},duration_seconds:@duration)
    end

    def assistant!(data)
      choice = data.is_a?(Hash) && data["choices"].is_a?(Array) && data["choices"].size == 1 && data["choices"].first
      message = choice.is_a?(Hash) && choice["message"]
      raise Error.new(:invalid_response) unless data.is_a?(Hash) && data["model"] == Protocol::MODEL && message.is_a?(Hash) && message["role"] == "assistant"
      [choice, message]
    end

    def usage(data)
      (data["usage"].is_a?(Hash) ? data["usage"] : {}).slice("prompt_tokens", "completion_tokens", "total_tokens").select { |_key, value| value.is_a?(Integer) && value >= 0 }
    end

    def exchange(payload)
      key = ENV["GROQ_API_KEY"].to_s.strip
      raise Error.new(:configuration) if key.empty? || key.match?(/[\s\x00-\x1F]/)
      Pacing.reserve!(payload)
      request = Net::HTTP::Post.new(ENDPOINT)
      request["Authorization"] = "Bearer #{key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)
      http = self.class.http_factory.call(ENDPOINT)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout, http.read_timeout, http.write_timeout, http.max_retries = 3, 15, 5, 0
      raw = +""
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      Timeout.timeout(25) do
        http.start do |connection|
          connection.request(request) do |response|
            Pacing.observe(response)
            status = response.code.to_i
            unless status == 200
              error_body = +""
              response.read_body do |chunk|
                error_body << chunk
                break if error_body.bytesize > MAX_RESPONSE_BYTES
              end
              provider_error = JSON.parse(error_body).dig("error", "code") rescue nil
              provider_error = "unclassified" unless %w[tool_use_failed json_validate_failed model_not_found invalid_api_key rate_limit_exceeded].include?(provider_error)
              ActiveSupport::Notifications.instrument("failure.page_agent", status: status, code: provider_error)
              code = case status
              when 401, 403 then :provider_auth
              when 400, 404, 422 then :model_unavailable
              when 429 then :rate_limited
              else :unavailable
              end
              code = :tool_call_failed if provider_error == "tool_use_failed"
              code = :invalid_response if provider_error == "json_validate_failed"
              raise Error.new(code, retry_after: status == 429 ? Pacing.retry_after : nil)
            end
            response.read_body do |chunk|
              raw << chunk
              raise Error.new(:invalid_response) if raw.bytesize > MAX_RESPONSE_BYTES
            end
          end
        end
      end
      @duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(3)
      JSON.parse(raw)
    rescue JSON::ParserError
      raise Error.new(:invalid_response)
    rescue Timeout::Error
      raise Error.new(:timeout)
    rescue SocketError, IOError, SystemCallError, OpenSSL::SSL::SSLError
      raise Error.new(:unavailable)
    end
  end
end
