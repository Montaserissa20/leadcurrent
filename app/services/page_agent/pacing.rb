module PageAgent
  # Provider headers drive the token budget. No account secrets or content are stored.
  # This shares the existing process-local provider store; a shared store is required for multiple workers.
  class Pacing
    STORE = RequestGate::STORE
    MUTEX = RequestGate::MUTEX
    KEY = "agent:provider:token_budget"

    def self.reserve!(payload)
      estimate = (JSON.generate(payload[:messages]).bytesize / 3.0).ceil + payload.fetch(:max_completion_tokens)
      MUTEX.synchronize do
        state = STORE.read(KEY)
        return unless state && state[:reset_at] > Time.current.to_f
        wait = (state[:reset_at] - Time.current.to_f).ceil.clamp(1, 180)
        raise Error.new(:rate_limited, retry_after: wait) if state[:cooldown] || state[:remaining] < estimate
        state[:remaining] -= estimate
        STORE.write(KEY, state, expires_in: 3.minutes)
      end
    end

    def self.observe(response)
      return unless response.respond_to?(:[])
      remaining = response["x-ratelimit-remaining-tokens"].to_s
      reset = response["x-ratelimit-reset-tokens"].to_s
      retry_seconds = response["retry-after"].to_s
      cooldown = response.code.to_i == 429
      seconds = if cooldown && retry_seconds.match?(/\A\d+(?:\.\d+)?\z/)
        retry_seconds.to_f.ceil.clamp(1, 180)
      elsif (match = reset.match(/\A(?:(\d+)m)?(\d+(?:\.\d+)?)s\z/))
        (match[1].to_i * 60 + match[2].to_f).ceil.clamp(1, 180)
      end
      return unless seconds && (cooldown || remaining.match?(/\A\d{1,8}\z/))
      MUTEX.synchronize do
        STORE.write(KEY, {remaining: remaining.to_i, reset_at: Time.current.to_f + seconds, cooldown: cooldown}, expires_in: 3.minutes)
      end
    end

    def self.retry_after
      state = STORE.read(KEY)
      state && state[:reset_at] > Time.current.to_f ? (state[:reset_at] - Time.current.to_f).ceil.clamp(1, 180) : 60
    end
  end
end
