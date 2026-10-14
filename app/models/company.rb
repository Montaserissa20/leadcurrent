class Company < ApplicationRecord
  include TenantRecord
  has_many :contacts
  validates :name, presence: true, length: { maximum: 150 }
end
