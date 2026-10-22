class AgentInquiry < ApplicationRecord
  STATUSES = %w[pending_review needs_information accepted rejected].freeze
  SOURCE_FIELDS = %w[organization_id agent_credential_id company_name contact_name contact_email product_or_service quantity currency stated_budget requirements desired_timeline message submitted_at idempotency_digest payload_digest submitted_payload].freeze
  belongs_to :organization
  belongs_to :agent_credential
  belongs_to :reviewed_by, class_name: "User", optional: true
  belongs_to :accepted_lead, class_name: "Lead", optional: true
  attr_accessor :review_change
  validates :status, inclusion: { in: STATUSES }
  validates :company_name, presence: true, length: { maximum: 150 }
  validates :product_or_service, presence: true, length: { maximum: 200 }
  validates :message, presence: true, length: { maximum: 2000 }
  validates :contact_name, length: { maximum: 150 }
  validates :contact_email, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :requirements, length: { maximum: 3000 }
  validates :desired_timeline, length: { maximum: 200 }
  validates :review_reason, length: { maximum: 500 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1_000_000 }, allow_nil: true
  validates :currency, inclusion: { in: %w[USD EUR TRY] }, allow_nil: true
  validates :stated_budget, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999_999_999.99 }, allow_nil: true
  validates :submitted_at, :idempotency_digest, :payload_digest, :submitted_payload, presence: true
  validate :intake_guards

  def reviewable? = status.in?(%w[pending_review needs_information])
  def missing_lead_fields = %w[contact_name contact_email].select { |field| public_send(field).blank? }

  private
  def intake_guards
    [agent_credential, reviewed_by, accepted_lead].compact.each do |record|
      errors.add(:base, "Related records must belong to this workspace") unless record.organization_id == organization_id
    end
    errors.add(:currency, "is required with a stated budget") if stated_budget && currency.nil?
    if new_record?
      errors.add(:status, "must start pending human review") unless status == "pending_review" && reviewed_by_id.nil? && reviewed_at.nil? && accepted_lead_id.nil?
    else
      errors.add(:base, "Original agent submission is immutable") if SOURCE_FIELDS.any? { |field| will_save_change_to_attribute?(field) }
      if %w[status reviewed_by_id reviewed_at accepted_lead_id review_reason].any? { |field| will_save_change_to_attribute?(field) } && !review_change
        errors.add(:base, "Use the authorized inquiry review action")
      end
    end
    if status == "accepted"
      errors.add(:base, "An accepted inquiry requires its lead and contact information") if accepted_lead.nil? || missing_lead_fields.any?
    elsif accepted_lead_id
      errors.add(:accepted_lead, "requires an accepted inquiry")
    end
  end
end
