require "digest"
class AgentCredential < ApplicationRecord
  TOKEN_PATTERN = /\Alc_agent_([a-f0-9]{24})\.([A-Za-z0-9_-]{43})\z/
  belongs_to :organization
  belongs_to :created_by, class_name: "User"
  has_many :agent_inquiries, dependent: :restrict_with_exception
  attr_accessor :revocation_change
  validates :name, presence: true, length: { maximum: 80 }
  validates :identifier, format: { with: /\A[a-f0-9]{24}\z/ }, uniqueness: true
  validates :token_digest, format: { with: /\A[a-f0-9]{64}\z/ }, uniqueness: true
  validates :scope, inclusion: { in: ["inquiries:create"] }
  validate :guard_credential

  def active? = revoked_at.nil? && (expires_at.nil? || expires_at > Time.current) && scope == "inquiries:create"

  def self.issue!(actor:, name:, expires_at: nil)
    raise WorkflowError, "Only workspace managers can manage agent credentials" unless actor.manager?
    identifier = SecureRandom.hex(12)
    token = "lc_agent_#{identifier}.#{SecureRandom.urlsafe_base64(32, false)}"
    transaction do
      credential = create!(organization: actor.organization, created_by: actor, name: name, expires_at: expires_at, identifier: identifier, token_digest: Digest::SHA256.hexdigest(token))
      AuditEvent.record!(actor, credential, "agent_credential_created", scope: credential.scope)
      [credential, token]
    end
  end

  def self.authenticate(token)
    match = token.is_a?(String) && token.bytesize <= 100 && TOKEN_PATTERN.match(token)
    return unless match
    credential = find_by(identifier: match[1])
    valid = ActiveSupport::SecurityUtils.secure_compare(Digest::SHA256.hexdigest(token), credential&.token_digest || ("0" * 64))
    credential if valid && credential&.active?
  end

  def revoke!(actor:)
    raise WorkflowError, "Only workspace managers can manage agent credentials" unless actor.manager?
    WorkspaceAccess.authorize!(actor, self)
    with_lock do
      WorkspaceAccess.authorize!(actor, self)
      raise WorkflowError, "This credential has already been revoked" if revoked_at
      self.revocation_change = true
      update!(revoked_at: Time.current)
      AuditEvent.record!(actor, self, "agent_credential_revoked")
    ensure
      self.revocation_change = false
    end
  end

  private
  def guard_credential
    errors.add(:created_by, "must belong to this workspace") if created_by && created_by.organization_id != organization_id
    errors.add(:expires_at, "must be in the future") if new_record? && expires_at && expires_at <= Time.current
    errors.add(:name, "must not contain a credential") if name.to_s.include?("lc_agent_")
    return unless persisted?
    immutable = %w[organization_id created_by_id identifier token_digest scope expires_at name]
    errors.add(:base, "Agent credential identity is immutable") if immutable.any? { |field| will_save_change_to_attribute?(field) }
    errors.add(:base, "Use the authorized revoke action") if will_save_change_to_revoked_at? && !revocation_change
  end
end
