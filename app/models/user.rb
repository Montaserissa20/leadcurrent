class User < ApplicationRecord
  belongs_to :organization
  has_secure_password
  normalizes :email, with: ->(value) { value.strip.downcase }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { maximum: 150 }
  validates :password, length: { minimum: 12 }, if: -> { new_record? || password.present? }
  validates :role, inclusion: { in: %w[manager salesperson] }
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) + ["Europe/Istanbul", "UTC"] }
  def manager? = role == "manager"
end
