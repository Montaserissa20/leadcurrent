ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
class ActiveSupport::TestCase
  # Time travel changes the global clock; keep these tests sequential.
  self.use_transactional_tests = true
  def make_user(organization: nil, role: "manager")
    organization ||= Organization.create!(name: "Test workspace")
    User.create!(organization: organization, name: "Alex Morgan", email: "alex-#{SecureRandom.hex(5)}@example.test", password: "test-password-123", role: role)
  end
  def make_lead(user, created_at: Time.current)
    company = Company.create!(organization: user.organization, name: "Atlas Industries")
    contact = Contact.create!(organization: user.organization, company: company, name: "Sam Taylor", email: "sam@example.test")
    Lead.create!(organization: user.organization, owner: user, company: company, contact: contact, title: "Enterprise agreement", created_at: created_at)
  end
  def qualify(lead, actor: lead.owner)
    RecordActivity.call(lead, actor: actor, kind: "contact", body: "Completed discovery call")
    LeadTransition.call(lead, to: "qualified", actor: actor)
    lead
  end
  def convert(lead, actor: lead.owner, value: 12000, currency: "USD")
    LeadConversion.call(lead, actor: actor, attributes: { title: lead.title, value: value, currency: currency, expected_closing_date: 20.days.from_now.to_date })
  end
  def make_opportunity(user)
    convert(qualify(make_lead(user)))
  end
end
class ActionDispatch::IntegrationTest
  def login(user)
    post login_path, params: { email: user.email, password: "test-password-123" }
    assert_redirected_to root_path
  end
end
