class AuditEvent < ApplicationRecord
  include TenantRecord
  belongs_to :actor, class_name: "User"
  validates :record_type, :record_id, :action, presence: true
  def self.record!(actor, record, action, details = {})
    create!(organization: actor.organization, actor: actor, record_type: record.class.name, record_id: record.id, action: action, details: details)
  end
end
