module Ai
  class RequestGate
    STORE = ActiveSupport::Cache::MemoryStore.new
    MUTEX = Mutex.new
    IN_FLIGHT = {}
    LIMITS = { user: 5, workspace: 10, provider: 20 }.freeze

    def self.call(user)
      token = Object.new
      MUTEX.synchronize do
        raise Error.new(:busy) if IN_FLIGHT.key?(user.id)
        buckets = { user: user.id, workspace: user.organization_id, provider: "groq" }
        raise Error.new(:rate_limited) if buckets.any? { |kind, id| STORE.read("#{kind}:#{id}").to_i >= LIMITS.fetch(kind) }
        buckets.each { |kind, id| STORE.increment("#{kind}:#{id}", 1, expires_in: 1.minute) }
        IN_FLIGHT[user.id] = token
      end
      yield
    ensure
      MUTEX.synchronize { IN_FLIGHT.delete(user.id) if IN_FLIGHT[user.id].equal?(token) }
    end
  end
end
