module AgentIntake
  class Error < StandardError
    ERRORS = {
      invalid_json: [400, "Send a valid JSON object with unique field names."],
      invalid_fields: [422, "Inquiry fields do not match the documented schema."],
      invalid_idempotency_key: [400, "Supply an Idempotency-Key of 16–100 permitted characters."],
      unauthorized: [401, "A valid, active inquiries:create bearer credential is required."],
      idempotency_conflict: [409, "This idempotency key was already used with different content."],
      rate_limited: [429, "Request limit reached. Wait a minute before retrying with the same idempotency key."]
    }.freeze
    attr_reader :code, :status
    def initialize(code)
      @code, (@status, message) = code, ERRORS.fetch(code)
      super(message)
    end
  end
end
