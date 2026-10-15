class Lead < ApplicationRecord
  include TenantRecord
  STATUSES = %w[new contacted qualified converted disqualified].freeze
  belongs_to :owner, class_name: "User"
  belongs_to :company
  belongs_to :contact
  has_one :opportunity
  has_many :activities
  has_many :tasks
  attr_accessor :workflow_change
  before_validation :set_deadline, on: :create
  validates :title, presence: true, length: { maximum: 200 }
  validates :status, inclusion: { in: STATUSES }
  validates :first_contact_deadline, presence: true
  validate :guard_workflow
  scope :awaiting_contact, -> { where(first_contact_at: nil) }
  scope :overdue, -> { awaiting_contact.where.not(status: %w[converted disqualified]).where("first_contact_deadline < ?", Time.current) }
  def overdue? = FollowUpDeadline.overdue?(self)
  private
  def set_deadline
    self.created_at ||= Time.current
    self.first_contact_deadline = FollowUpDeadline.deadline(created_at)
  end
  def guard_workflow
    if persisted? && !workflow_change && (will_save_change_to_status? || will_save_change_to_first_contact_at? || will_save_change_to_first_contact_deadline?)
      errors.add(:base, "Use a workflow action to change status or first contact")
    end
    errors.add(:status, "must start as new") if new_record? && status != "new"
  end
end
