require "digest"
module AgentIntake
  class RequestGate
    STORE = ActiveSupport::Cache::MemoryStore.new(size: 1.megabyte)
    MUTEX = Mutex.new
    def self.check!(key, limit:)
      MUTEX.synchronize do
        raise Error.new(:rate_limited) if STORE.read(key).to_i >= limit
        STORE.increment(key, 1, expires_in: 1.minute)
      end
    end
    def self.ip!(ip) = check!("agent-intake:ip:#{Digest::SHA256.hexdigest(ip.to_s)}", limit: 60)
    def self.credential!(credential)
      check!("agent-intake:credential:#{credential.id}", limit: 10)
      check!("agent-intake:workspace:#{credential.organization_id}", limit: 30)
    end
  end
end
