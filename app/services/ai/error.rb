module Ai
  class Error < StandardError
    MESSAGES = {
      configuration: "LeadCurrent AI is not configured. Ask your administrator to configure Groq on the server.",
      provider_auth: "Groq could not authorize this request. Ask your administrator to check the server configuration.",
      model_unavailable: "The configured Groq model is unavailable. Ask your administrator to check GROQ_MODEL.",
      rate_limited: "AI request limit reached. Please wait a minute before trying again.",
      timeout: "Groq took too long to respond. Your customer record is unchanged; please try again.",
      unavailable: "Groq is temporarily unavailable. Your customer record is unchanged; please try again later.",
      invalid_response: "Groq returned an incomplete or invalid answer. Please try again; no CRM data was changed.",
      invalid_request: "Choose one of the four AI actions and keep your question to 600 characters.",
      context_limit: "This question and customer context exceed the AI request limit. Please try a shorter question.",
      busy: "An AI request is already running for your account. Please wait for it to finish."
    }.freeze
    attr_reader :code
    def initialize(code)
      @code = code
      super(MESSAGES.fetch(code))
    end
  end
end
