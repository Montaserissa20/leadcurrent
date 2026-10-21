module Copilot
  class Conversation
    STORE = ActiveSupport::Cache::MemoryStore.new(size: 2.megabytes)
    MUTEX = Mutex.new
    TTL = 10.minutes

    def self.clear_session(user,session_id)
      prefix = Regexp.escape("copilot:#{user.organization_id}:#{user.id}:#{session_id}:")
      MUTEX.synchronize { STORE.delete_matched(/\A#{prefix}/) }
    end

    def initialize(user, session_id, id = nil)
      @id = id || SecureRandom.uuid
      raise PageAgent::Error.new(:invalid_request) unless @id.is_a?(String) && @id.match?(/\A[0-9a-f-]{36}\z/)
      @key = "copilot:#{user.organization_id}:#{user.id}:#{session_id}:#{@id}"
      MUTEX.synchronize do
        @state = id ? STORE.read(@key) : {history:[], created_at:Time.current.to_f}
        raise PageAgent::Error.new(:conversation_expired) unless @state && Time.current.to_f - @state[:created_at] < 30.minutes
      end
    end
    attr_reader :id
    def history = @state[:history].last(4)

    def remember(question, plan)
      # Only bounded user text + intent descriptors go back to Groq, never retrieved CRM rows.
      descriptor = plan.slice("intent","query","audience","status","period","search","destination")
      @state[:history] << {question:Ai::SafeText.call(question,limit:600), previous:descriptor}
      @state[:history] = @state[:history].last(4)
      save
    end

    def pending(plan)
      run_id = SecureRandom.hex(16)
      @state[:pending] = {run_id:run_id,plan:plan,expires_at:5.minutes.from_now.to_f}
      save
      run_id
    end

    def consume(run_id)
      MUTEX.synchronize do
        state = STORE.read(@key)
        pending = state && state.delete(:pending)
        raise PageAgent::Error.new(:invalid_request) unless pending && pending[:expires_at] > Time.current.to_f && pending[:run_id] == run_id
        @state = state
        STORE.write(@key,state,expires_in:TTL)
        pending[:plan]
      end
    end

    def peek(run_id)
      MUTEX.synchronize do
        state=STORE.read(@key)
        pending=state && state[:pending]
        raise PageAgent::Error.new(:invalid_request) unless pending && pending[:expires_at] > Time.current.to_f && pending[:run_id] == run_id
        pending[:plan]
      end
    end

    private
    def save
      MUTEX.synchronize { STORE.write(@key,@state,expires_in:TTL) }
    end
  end
end
