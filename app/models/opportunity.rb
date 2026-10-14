class Opportunity < ApplicationRecord
  include TenantRecord
  STATUSES = %w[qualification proposal negotiation won lost].freeze
  CURRENCIES = %w[USD EUR TRY].freeze
  belongs_to :owner, class_name: "User"
  belongs_to :company
  belongs_to :contact
  belongs_to :lead
  has_many :activities
  has_many :tasks
  attr_accessor :workflow_change
  validates :title, presence: true, length: { maximum: 200 }
  validates :status, inclusion: { in: STATUSES }
  validates :currency, inclusion: { in: CURRENCIES }
  validates :value, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000 }
  validates :expected_closing_date, :last_activity_at, presence: true
  validates :lead_id, uniqueness: true
  validate :guard_workflow
  scope :active, -> { where.not(status: %w[won lost]) }
  def terminal? = status.in?(%w[won lost])
  private
  def guard_workflow
    errors.add(:status, "must be changed through a workflow action") if persisted? && will_save_change_to_status? && !workflow_change
    errors.add(:base, "Create opportunities by converting a qualified lead") if new_record? && (!workflow_change || lead&.status != "qualified" || status != "qualification")
  end
end
