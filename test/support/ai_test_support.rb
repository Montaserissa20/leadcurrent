module AiTestSupport
  class Response
    attr_reader :code
    def initialize(code, body)
      @code, @body = code.to_s, body
    end
    def read_body
      @body.bytes.each_slice(1_024) { |bytes| yield bytes.pack("C*") }
    end
  end

  class Http
    attr_accessor :use_ssl, :verify_mode, :open_timeout, :read_timeout, :write_timeout, :max_retries
    def initialize(&handler) = @handler = handler
    def start = yield(self)
    def request(request) = yield(@handler.call(request))
  end

  def install_fake_groq
    @original_groq_env = ENV.to_h.slice("GROQ_API_KEY", "GROQ_MODEL")
    @original_groq_factory = Ai::GroqClient.http_factory
    @ai_api_key = SecureRandom.hex(24)
    ENV["GROQ_API_KEY"] = @ai_api_key
    ENV["GROQ_MODEL"] = Ai::GroqClient::DEFAULT_MODEL
    @ai_requests = []
    @ai_status = 200
    @ai_delay = 0
    @ai_http = Http.new do |request|
      raise @ai_exception if @ai_exception
      payload = JSON.parse(request.body)
      @ai_requests << payload
      @ai_authorization = request["Authorization"]
      sleep @ai_delay if @ai_delay.positive?
      input = JSON.parse(payload.fetch("messages").last.fetch("content"))
      draft = input["task"] == "Draft follow-up"
      answer = @ai_answer || {
        summary: "Review the Atlas Industries software-subscription opportunity.", evidence_ids: %w[customer record history],
        risks: ["Budget approval is not confirmed."], next_step: "Ask about the required seats and decision process.",
        explanation: "Use the recorded context and official deadline; verify the customer's requirements.",
        assumptions: ["The decision-maker is unknown."], draft: draft ? "Hello Atlas Industries,\nCould we confirm your subscription requirements?\nPlease review before sending." : ""
      }
      body = @ai_raw || JSON.generate(model: payload["model"], choices: [{ finish_reason: "stop", message: { role: "assistant", content: JSON.generate(answer) } }], usage: { prompt_tokens: 120, completion_tokens: 80, total_tokens: 200 })
      Response.new(@ai_status, body)
    end
    Ai::GroqClient.http_factory = ->(_uri) { @ai_http }
    Ai::RequestGate::STORE.clear
    Ai::RequestGate::MUTEX.synchronize { Ai::RequestGate::IN_FLIGHT.clear }
  end

  def restore_fake_groq
    Ai::GroqClient.http_factory = @original_groq_factory
    %w[GROQ_API_KEY GROQ_MODEL].each { |key| @original_groq_env.key?(key) ? ENV[key] = @original_groq_env[key] : ENV.delete(key) }
    Ai::RequestGate::STORE.clear
    Ai::RequestGate::MUTEX.synchronize { Ai::RequestGate::IN_FLIGHT.clear }
  end
end
