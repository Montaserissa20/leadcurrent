class Contact < ApplicationRecord
  include TenantRecord
  belongs_to :company
  validates :name, presence: true, length: { maximum: 150 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
