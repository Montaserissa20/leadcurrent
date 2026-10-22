# Explicit local real-Groq acceptance. Fictional Rails test transaction rolls back.
abort "Set LEADCURRENT_LIVE_AGENT_CUSTOMER=1 to opt in." unless ENV["LEADCURRENT_LIVE_AGENT_CUSTOMER"] == "1"
abort "Local test only; never CI/production." if ENV["CI"] || ENV["RAILS_ENV"] && ENV["RAILS_ENV"] != "test"
abort "Server Groq key is missing." if ENV["GROQ_API_KEY"].to_s.strip.empty?
ENV["RAILS_ENV"] = "test"
ENV["LEADCURRENT_LIVE_AGENT"] = "1"
$LOAD_PATH.unshift(File.expand_path("../test", __dir__))
require_relative "../test/application_system_test_case"
require "json"
require "open3"
require "fileutils"
require "socket"

Capybara.server_host = "127.0.0.1"
Capybara.server_port = 3170
class AgentCustomerLiveCheck < ApplicationSystemTestCase
  test "separate real AI buyer submits to actual Rails human qualification approval and existing AI features" do
    report = { started_at: Time.now.utc.iso8601, mocked: false, result: "FAIL", steps: [], completions: [], paid_cost: "not measured", human_hours: "not measured", production: "not contacted" }
    subscriptions = %w[completion.ai completion.copilot completion.page_agent].map do |name|
      ActiveSupport::Notifications.subscribe(name) do |_n, _s, _f, _id, payload|
        report[:completions] << payload.slice(:model, :usage, :action, :duration_seconds).merge(surface: name)
      end
    end
    previous_wait = Capybara.default_max_wait_time
    Capybara.default_max_wait_time = 35
    user = make_user
    original = [Lead, Company, Contact, Activity, Opportunity, Task].to_h { |model| [model.name, model.count] }
    visit login_path
    fill_in "Email address", with: user.email
    fill_in "Password", with: "test-password-123"
    click_button "Sign in →"
    click_link "Agent Inquiries", exact: true
    click_link "Manage agent credentials"
    fill_in "Credential name", with: "Fictional external buyer demo"
    click_button "Generate credential"
    assert_text "Credential created"
    token = find("#agent-issued-token").text
    assert_match AgentCredential::TOKEN_PATTERN, token
    credential = AgentCredential.authenticate(token)
    assert_equal user.organization_id, credential.organization_id
    click_link "Back to credentials"
    assert_no_text token
    report[:steps] << { name: "manager UI issues workspace-bound digest-only credential", result: "PASS", secret_logged: false }
    child_env = { "LEADCURRENT_BASE_URL" => "http://127.0.0.1:3170", "LEADCURRENT_AGENT_TOKEN" => token, "GROQ_API_KEY" => ENV.fetch("GROQ_API_KEY") }
    client = Rails.root.join("examples/purchasing_agent/client.py").to_s
    run_client = lambda do |*args|
      output, _errors, status = Open3.capture3(child_env, ENV.fetch("PYTHON", "python"), client, *args)
      raise "Child response contained a credential; details withheld" if [token, ENV.fetch("GROQ_API_KEY")].any? { |secret| output.include?(secret) }
      data = JSON.parse(output)
      report[:buyer_attempts] ||= []
      report[:buyer_attempts] << data
      assert status.success?, "Buyer client did not complete; see safe error_code in report."
      data
    end
    deterministic = run_client.call("--mode", "deterministic", "--idempotency-key", "phase3-mode-a-demo-20261022")
    assert_equal 201, deterministic.fetch("http_status")
    replay = run_client.call("--mode", "deterministic", "--idempotency-key", "phase3-mode-a-demo-20261022")
    assert_equal 200, replay.fetch("http_status")
    assert_equal deterministic.dig("receipt", "inquiry_id"), replay.dig("receipt", "inquiry_id")
    assert_equal original, [Lead, Company, Contact, Activity, Opportunity, Task].to_h { |model| [model.name, model.count] }
    report[:steps] << { name: "separate deterministic Python process makes real HTTP submission and durable replay", result: "PASS", groq_calls: 0 }

    buyer = run_client.call("--mode", "ai", "--goal", "We are a fictional startup seeking pricing for 50 business software subscriptions with team management and reporting. Our proposed budget is 10000 USD, not approved. Desired timeline is within 30 days. Request a quotation, not a purchase.", "--company", "Fictional Meridian Procurement", "--contact-name", "Fictional Alex Buyer", "--contact-email", "buyer@example.test", "--idempotency-key", "phase3-mode-b-demo-20261022")
    assert_equal 201, buyer.fetch("http_status")
    inquiry = AgentInquiry.find(buyer.dig("receipt", "inquiry_id"))
    assert_equal "pending_review", inquiry.status
    assert_equal "Fictional Meridian Procurement", inquiry.company_name
    assert_equal 50, inquiry.quantity
    assert_equal 10000, inquiry.stated_budget
    assert_equal user.organization_id, inquiry.organization_id
    assert_equal original, [Lead, Company, Contact, Activity, Opportunity, Task].to_h { |model| [model.name, model.count] }
    report[:steps] << { name: "real Groq buyer in separate Python process submits actual pending inquiry", result: "PASS", usage: buyer["usage"], http_status: 201 }
    visit agent_inquiries_path
    assert_text "Fictional Meridian Procurement"
    assert_text "Identity: Unverified"
    FileUtils.mkdir_p(Rails.root.join(".local/phase3-preview"))
    save_screenshot(Rails.root.join(".local/phase3-preview/inbox.png"))
    visit agent_inquiry_path(inquiry)
    before_analysis = inquiry.attributes
    click_button "Analyze with AI"
    assert_selector ".inquiry-ai-answer"
    assert_text "AI INTERPRETATION"
    assert_equal before_analysis, inquiry.reload.attributes
    assert_selector ".inquiry-ai-answer", text: /50/
    report[:steps] << { name: "real Groq qualification of saved inquiry; decision unchanged", result: "PASS" }
    click_button "Accept inquiry"
    assert_text "Inquiry accepted."
    lead = inquiry.reload.accepted_lead
    assert_equal "accepted", inquiry.status
    assert_equal user.organization_id, lead.organization_id
    assert_equal user.id, lead.owner_id
    assert_equal "new", lead.status
    assert_nil lead.first_contact_at
    assert_equal 24.hours, lead.first_contact_deadline - lead.created_at
    assert_equal 0, lead.activities.count
    assert_equal 0, lead.tasks.count
    assert_nil lead.opportunity
    assert_link "Review source inquiry →", href: agent_inquiry_path(inquiry)
    assert AuditEvent.where(record_type: "AgentInquiry", record_id: inquiry.id, action: "agent_inquiry_accepted").exists?
    save_screenshot(Rails.root.join(".local/phase3-preview/accepted-lead.png"))
    report[:steps] << { name: "human acceptance through CreateLead yields linked New lead with 24-hour deadline and audit, no contact/purchase", result: "PASS" }

    # One conservative test-only minute boundary between two pairs of real calls.
    # Do not clear/increase production/provider limits or retry a failed model response.
    report[:test_harness_quota_wait_seconds] = 60
    puts JSON.generate(test_harness_quota_wait_seconds: 60, before: "Phase1 and Phase2 regression questions")
    2.times { sleep 30 }
    within(".ai-panel") { click_button "Analyze customer" }
    assert_selector ".ai-answer", wait: 40
    assert_no_selector ".ai-error"
    report[:steps] << { name: "existing Phase1 real Groq Sales Assistant analyzes the accepted lead", result: "PASS" }
    click_button "AI Agent"
    within("#agent-panel") { fill_in "What would you like to do?", with: "Which leads do we have?"; click_button "Run" }
    assert_selector "#leadcurrent-agent[data-status=completed]", wait: 75
    answer = page.all(".copilot-message[data-role=assistant]").last
    assert_includes answer.text, "Verified CRM data"
    within(answer) { assert_link lead.title, href: lead_path(lead) }
    report[:steps] << { name: "existing Phase2 real Groq Copilot finds the accepted lead through authorized database queries", result: "PASS" }
    assert_equal "new", lead.reload.status
    assert_nil lead.first_contact_at
    assert_equal 0, lead.activities.count
    assert_equal 0, lead.tasks.count
    assert_not page.html.include?(token)
    report[:result] = "PASS"
  ensure
    subscriptions&.each { |subscription| ActiveSupport::Notifications.unsubscribe(subscription) }
    Capybara.default_max_wait_time = previous_wait if previous_wait
    if report
      report[:finished_at] = Time.now.utc.iso8601
      report[:usage] = report[:completions].each_with_object(Hash.new(0)) { |entry, sum| entry.fetch(:usage, {}).each { |key, value| sum[key] += value } }
      report[:buyer_usage] = report.fetch(:buyer_attempts, []).select { |entry| entry["mode"] == "ai" }.each_with_object(Hash.new(0)) { |entry, sum| entry.fetch("usage", {}).each { |key, value| sum[key] += value } }
      report[:fixture_lifecycle] = "Fictional local test transaction rolls back; existing development database not modified."
      path = Rails.root.join(".local", "phase3-real-#{report[:started_at].delete('^0-9')}.json")
      File.write(path, JSON.pretty_generate(report))
      File.write(Rails.root.join(".local/phase3-real-latest.json"), JSON.pretty_generate(report))
      puts JSON.generate(report.slice(:result, :started_at, :finished_at, :usage, :buyer_usage))
    end
  end
end
