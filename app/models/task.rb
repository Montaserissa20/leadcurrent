class Task < ApplicationRecord
  include TenantRecord
  belongs_to :owner, class_name: "User"
  belongs_to :lead, optional: true
  belongs_to :opportunity, optional: true
  validates :title, presence: true, length: { maximum: 200 }
  validates :due_at, presence: true
  validate { errors.add(:base, "Choose exactly one record") unless [lead, opportunity].compact.size == 1 }
  scope :pending, -> { where(completed_at: nil) }
  scope :overdue, -> { pending.where("due_at < ?", Time.current) }
  def record = lead || opportunity
end
