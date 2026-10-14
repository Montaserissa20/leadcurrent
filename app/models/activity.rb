class Activity < ApplicationRecord
  include TenantRecord
  belongs_to :actor, class_name: "User"
  belongs_to :lead, optional: true
  belongs_to :opportunity, optional: true
  validates :kind, inclusion: { in: %w[contact note] }
  validates :body, presence: true, length: { maximum: 5000 }
  validates :completed_at, presence: true
  validate { errors.add(:base, "Choose exactly one record") unless [lead, opportunity].compact.size == 1 }
  validate { errors.add(:completed_at, "cannot be in the future") if completed_at && completed_at > Time.current }
end
