require "net/http"
require "json"
require "timeout"

module Ai
  class GroqClient
    ENDPOINT = URI("https://api.groq.com/openai/v1/chat/completions").freeze
    DEFAULT_MODEL = "openai/gpt-oss-20b"
    MAX_INPUT_BYTES = 6_000
    MAX_COMPLETION_TOKENS = 1_200
    MAX_RESPONSE_BYTES = 32_768
    # Narrow transport injection for deterministic tests; never selected from request parameters.
    class_attribute :http_factory, default: ->(uri) { Net::HTTP.new(uri.host, uri.port) }, instance_writer: false
    Reply = Data.define(:content, :model, :usage)

    def initialize(api_key: ENV["GROQ_API_KEY"], model: ENV.fetch("GROQ_MODEL", DEFAULT_MODEL))
      @api_key = api_key.to_s.strip
      @model = model.to_s.presence || DEFAULT_MODEL
    end

    def call(messages:, response_schema: nil)
      raise Error.new(:configuration) if @api_key.empty? || @api_key.match?(/[\s\x00-\x1F]/) || !@model.match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.\/-]{0,99}\z/)
      raise Error.new(:context_limit) if messages.sum { |message| message.fetch(:content).bytesize } > MAX_INPUT_BYTES
      request = Net::HTTP::Post.new(ENDPOINT)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      payload = { model: @model, messages: messages, temperature: 0.2, max_completion_tokens: MAX_COMPLETION_TOKENS,
        response_format: { type: "json_object" }, tool_choice: "none", stream: false }
      payload[:reasoning_effort] = "low" if @model.start_with?("openai/gpt-oss-")
      if response_schema && %w[openai/gpt-oss-20b openai/gpt-oss-120b].include?(@model)
        payload[:response_format] = { type: "json_schema", json_schema: { name: "sales_advice", strict: true, schema: response_schema } }
      end
      request.body = JSON.generate(payload)
      http = self.class.http_factory.call(ENDPOINT)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = 3
      http.read_timeout = 15
      http.write_timeout = 5
      http.max_retries = 0
      body = +""
      Timeout.timeout(25) do
        http.start do |connection|
          connection.request(request) do |response|
            check_status!(response.code.to_i)
            response.read_body do |chunk|
              body << chunk
              raise Error.new(:invalid_response) if body.bytesize > MAX_RESPONSE_BYTES
            end
          end
        end
      end
      data = JSON.parse(body)
      choice = data.is_a?(Hash) && data["choices"].is_a?(Array) && data["choices"].sole
      message = choice.is_a?(Hash) && choice["message"]
      unless choice && choice["finish_reason"] == "stop" && message.is_a?(Hash) && message["role"] == "assistant" &&
          message["content"].is_a?(String) && message["content"].present? && message["tool_calls"].blank? && data["model"] == @model
        raise Error.new(:invalid_response)
      end
      usage = (data["usage"].is_a?(Hash) ? data["usage"] : {}).slice("prompt_tokens", "completion_tokens", "total_tokens")
        .select { |_key, value| value.is_a?(Integer) && value >= 0 }
      # Optional metrics contain only provider/model token counts, never prompts, records or responses.
      ActiveSupport::Notifications.instrument("completion.ai", model: @model, usage: usage)
      Reply.new(content: message["content"], model: @model, usage: usage)
    rescue JSON::ParserError, Enumerable::SoleItemExpectedError, TypeError
      raise Error.new(:invalid_response)
    rescue Timeout::Error
      raise Error.new(:timeout)
    rescue SocketError, IOError, SystemCallError, OpenSSL::SSL::SSLError
      raise Error.new(:unavailable)
    end

    private
    def check_status!(status)
      return if status == 200
      code = case status
      when 401, 403 then :provider_auth
      when 400, 404, 422 then :model_unavailable
      when 429 then :rate_limited
      else :unavailable
      end
      raise Error.new(code)
    end
  end
end
