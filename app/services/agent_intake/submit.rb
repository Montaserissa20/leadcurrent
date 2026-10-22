require "digest"
module AgentIntake
  class Submit
    def self.call(credential:, payload:, idempotency_key:)
      raise Error.new(:invalid_idempotency_key) unless idempotency_key.is_a?(String) && idempotency_key.match?(/\A[A-Za-z0-9._:-]{16,100}\z/)
      key_digest = Digest::SHA256.hexdigest(idempotency_key)
      credential.with_lock do
        raise Error.new(:unauthorized) unless credential.active?
        inquiry = AgentInquiry.find_by(agent_credential_id: credential.id, idempotency_digest: key_digest)
        if inquiry
          raise Error.new(:idempotency_conflict) unless inquiry.payload_digest == payload.digest
          return [inquiry, true]
        end
        inquiry = AgentInquiry.create!(payload.attributes.merge(organization: credential.organization, agent_credential: credential, submitted_at: Time.current,
          submitted_payload: payload.original, payload_digest: payload.digest, idempotency_digest: key_digest))
        [inquiry, false]
      end
    end
  end
end
