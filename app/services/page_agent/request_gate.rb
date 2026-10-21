module PageAgent
  class RequestGate
    # Share the provider budget/in-flight ownership with Phase 1 without changing its client or rules.
    STORE = Ai::RequestGate::STORE
    MUTEX = Ai::RequestGate::MUTEX
    IN_FLIGHT = Ai::RequestGate::IN_FLIGHT
    def self.call(user)
      token = Object.new
      MUTEX.synchronize do
        raise Error.new(:busy) if IN_FLIGHT.key?(user.id)
        minute = { "agent:user:#{user.id}" => 8, "agent:workspace:#{user.organization_id}" => 12, "provider:groq" => 16 }
        daily = { "agent:daily:user:#{user.id}" => 300, "agent:daily:workspace:#{user.organization_id}" => 600, "agent:daily:provider" => 800 }
        raise Error.new(:rate_limited, retry_after: 86_400) if daily.any? { |key, limit| STORE.read(key).to_i >= limit }
        limited = minute.find { |key, limit| STORE.read(key).to_i >= limit }
        if limited
          reset = STORE.read("agent:reset:#{limited.first}") || 1.minute.from_now.to_f
          raise Error.new(:rate_limited, retry_after: (reset-Time.current.to_f).ceil.clamp(1,60))
        end
        minute.each_key do |key|
          STORE.write("agent:reset:#{key}",1.minute.from_now.to_f,expires_in:1.minute) if STORE.read(key).to_i.zero?
          STORE.increment(key, 1, expires_in: 1.minute)
        end
        daily.each_key { |key| STORE.increment(key, 1, expires_in: 24.hours) }
        IN_FLIGHT[user.id] = token
      end
      yield
    ensure
      MUTEX.synchronize { IN_FLIGHT.delete(user.id) if IN_FLIGHT[user.id].equal?(token) }
    end
  end
end
