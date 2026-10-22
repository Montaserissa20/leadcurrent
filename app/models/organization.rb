class Organization < ApplicationRecord
  %i[users companies contacts leads opportunities activities tasks audit_events agent_credentials agent_inquiries].each { |name| has_many name }
  validates :name, presence: true, length: { maximum: 150 }
end
