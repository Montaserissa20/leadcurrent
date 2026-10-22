require "application_system_test_case"
require_relative "../support/agent_intake_test_support"
require_relative "../support/ai_test_support"
require "net/http"

class AgentIntakeBrowserTest < ApplicationSystemTestCase
  include AgentIntakeTestSupport
  include AiTestSupport
  setup do
    @user = make_user
    AgentIntake::RequestGate::STORE.clear
    install_fake_groq
    @ai_answer = qualification_answer
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.current_window.resize_to(1440, 1050)
    visit login_path
    fill_in "Email address", with: @user.email
    fill_in "Password", with: "test-password-123"
    click_button "Sign in →"
    assert_text "Make your next move count."
  end
  teardown do
    restore_fake_groq
    AgentIntake::RequestGate::STORE.clear
  end
  def submit_over_http(token, payload, key: SecureRandom.hex(16))
    uri = URI(page.current_url)
    uri.path = "/api/v1/agent_inquiries"; uri.query = nil
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{token}"
    request["Idempotency-Key"] = key
    request.body = JSON.generate(payload)
    Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  end
  test "manager issued credential receives a real HTTP inquiry and only human approval creates a normal lead" do
    click_link "Agent Inquiries", exact: true
    assert_text "No matching inquiries"
    click_link "Manage agent credentials"
    fill_in "Credential name", with: "Browser purchasing agent"
    click_button "Generate credential"
    assert_text "Credential created"
    token = find("#agent-issued-token").text
    assert_match AgentCredential::TOKEN_PATTERN, token
    page.execute_script("window.dispatchEvent(new Event('pagehide'))")
    assert_no_text token
    click_link "Back to credentials"
    assert_no_text token
    before = [Lead, Contact, Company, Activity, Opportunity, Task].map(&:count)
    response = submit_over_http(token, inquiry_payload, key: "browser-http-inquiry-123")
    assert_equal "201", response.code
    receipt = JSON.parse(response.body)
    inquiry = AgentInquiry.find(receipt.fetch("inquiry_id"))
    assert_equal before, [Lead, Contact, Company, Activity, Opportunity, Task].map(&:count)
    visit agent_inquiries_path
    assert_text "Fictional Atlas Procurement"
    assert_text "Identity: Unverified"
    click_link "Fictional Atlas Procurement", match: :first
    assert_text "Claimed purchasing request"
    click_button "Analyze with AI"
    assert_text "AI INTERPRETATION"
    assert_text "Buyer identity and purchasing authority remain unverified."
    assert_equal "pending_review", inquiry.reload.status
    assert_equal 1, @ai_requests.size
    select @user.name, from: "Lead owner"
    click_button "Accept inquiry"
    assert_text "Inquiry accepted."
    assert_text "Origin: External AI Agent inquiry"
    assert_text "Review source inquiry"
    assert_selector ".heading-actions .badge", text: "New"
    assert_selector ".ai-panel button[name=mode]", count: 4
    assert_button "AI Agent"
    lead = inquiry.reload.accepted_lead
    assert_equal lead_path(lead), page.current_path
    assert_equal @user.organization_id, lead.organization_id
    assert_nil lead.first_contact_at
    assert_equal 24.hours, lead.first_contact_deadline - lead.created_at
    assert_equal "accepted", inquiry.status
    assert_no_difference "Lead.count" do
      duplicate = submit_over_http(token, inquiry_payload, key: "browser-http-inquiry-123")
      assert_equal "200", duplicate.code
    end
    click_link "Review source inquiry →"
    assert_no_button "Accept inquiry"
    assert_link "Open created lead →", href: lead_path(lead)
  end

  test "mobile light and dark inbox keep claims readable and rejection never creates a customer" do
    inquiry = make_inquiry(@user, company_name: "Fictional mobile buyer", message: "<script>window.injected = true</script>", contact_name: nil, contact_email: nil)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
    page.current_window.resize_to(390, 844)
    %w[light dark].each do |theme|
      visit agent_inquiries_path
      page.execute_script("document.documentElement.dataset.theme=arguments[0]", theme)
      assert_text "Fictional mobile buyer"
      assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")
      visit agent_inquiry_path(inquiry)
      assert_text "Requester claims, not verified company information."
      assert_button "Accept inquiry", disabled: true
      assert_not page.evaluate_script("window.injected === true")
      assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")
    end
    fill_in "Review reason (optional)", with: "Contact details missing; no company verification."
    assert_no_difference "Lead.count" do
      click_button "Request more information"
      assert_text "Human review recorded."
      assert_text "Needs information"
      click_button "Reject inquiry"
      assert_text "Rejected"
    end
    assert_equal "rejected", inquiry.reload.status
  end
end
