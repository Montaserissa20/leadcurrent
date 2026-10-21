module PageAgent
  class Error < StandardError
    MESSAGES = Ai::Error::MESSAGES.merge(invalid_request: "Please use a shorter message or refresh the page and try again.", context_limit: "The visible page exceeds the agent context limit. Narrow the search and try again.", tool_call_failed: "I couldn't finish that browser action safely. Please try again or ask me to explain the manual steps.", conversation_expired: "This conversation has expired. Start a new conversation to continue.", unverified: "I couldn't verify the CRM result. Please try again; no changes were submitted.").freeze
    attr_reader :code, :retry_after
    def initialize(code, retry_after: nil)
      @code = code
      @retry_after = retry_after
      super(MESSAGES.fetch(code))
    end
  end
end
