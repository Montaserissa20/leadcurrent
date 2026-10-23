# Opt-in real deterministic HTTP demonstration, no model or provider token usage.
abort "Set LEADCURRENT_VERIFY_INTEGRATION=1 to opt in." unless ENV["LEADCURRENT_VERIFY_INTEGRATION"] == "1"
abort "Local test only; never CI/production." if ENV["CI"] || ENV["RAILS_ENV"] && ENV["RAILS_ENV"] != "test"
ENV["RAILS_ENV"] = "test"
ENV.delete("GROQ_API_KEY")
$LOAD_PATH.unshift(File.expand_path("../test", __dir__))
require_relative "../test/application_system_test_case"
require "net/http"
require "json"
require "open3"
require "fileutils"

Capybara.server_host = "127.0.0.1"
Capybara.server_port = 3170
class AgentIntegrationLiveCheck < ApplicationSystemTestCase
  test "public center to manager credential to separate deterministic Python and actual inbox" do
    report = { started_at: Time.now.utc.iso8601, result: "FAIL", groq_calls: 0, provider_tokens: 0, production_contacted: false, fictional_data: true, fixture_lifecycle: "Local Rails test transaction rolls back; development database untouched.", steps: [] }
    visit agent_integrations_path
    assert_selector "h1", text: "Agent Integrations"
    directory = Rails.root.join(".local/phase31-preview")
    FileUtils.mkdir_p(directory)
    page.execute_script("document.documentElement.dataset.theme='light'")
    save_screenshot(directory.join("integration-center-light.png"))
    page.execute_script("document.documentElement.dataset.theme='dark'")
    save_screenshot(directory.join("integration-center-dark.png"))
    page.driver.browser.manage.window.resize_to(390, 844)
    assert page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")
    save_screenshot(directory.join("integration-center-mobile.png"))
    page.driver.browser.manage.window.resize_to(1440, 1000)
    base = "http://127.0.0.1:3170"
    download = Net::HTTP.get_response(URI(base + agent_inquiries_openapi_path))
    assert_equal "200", download.code
    assert_equal File.binread(AgentIntegrationGuide::SPEC_PATH), download.body.b
    report[:steps] << { name: "Public integration center and actual OpenAPI HTTP download", result: "PASS" }
    user = make_user
    visit login_path
    fill_in "Email address", with: user.email
    fill_in "Password", with: "test-password-123"
    click_button "Sign in →"
    assert_current_path root_path
    visit agent_credentials_path
    assert_selector "h1", text: "Agent credentials"
    fill_in "Credential name", with: "Fictional independent developer test"
    click_button "Generate credential"
    token = find("#agent-issued-token").text
    assert_match AgentCredential::TOKEN_PATTERN, token
    click_link "Back to credentials"
    original = [Lead, Company, Contact, Opportunity].to_h { |model| [model.name, model.count] }
    environment = { "LEADCURRENT_BASE_URL" => base, "LEADCURRENT_AGENT_TOKEN" => token, "GROQ_API_KEY" => nil }
    command = [ENV.fetch("PYTHON", "python"), Rails.root.join("examples/purchasing_agent/client.py").to_s, "--mode", "deterministic", "--idempotency-key", "phase31-#{SecureRandom.hex(16)}"]
    reports = 2.times.map do
      stdout, _stderr, status = Open3.capture3(environment, *command)
      raise "Secret in client output; details withheld" if stdout.include?(token)
      output = JSON.parse(stdout)
      report[:client_attempts] ||= []
      report[:client_attempts] << output
      assert status.success?, "External deterministic process failed; see safe receipt/error code."
      output
    end
    assert_equal [201, 200], reports.map { |item| item.fetch("http_status") }
    assert_equal reports.first.dig("receipt", "inquiry_id"), reports.last.dig("receipt", "inquiry_id")
    assert_equal true, reports.last.dig("receipt", "replayed")
    assert_equal original, [Lead, Company, Contact, Opportunity].to_h { |model| [model.name, model.count] }
    inquiry = AgentInquiry.find(reports.first.dig("receipt", "inquiry_id"))
    assert_equal user.organization_id, inquiry.organization_id
    assert_equal "pending_review", inquiry.status
    assert_equal 1, AgentInquiry.where(agent_credential_id: inquiry.agent_credential_id).count
    visit agent_inquiries_path
    assert_text "Fictional Atlas Procurement"
    assert_text "Identity: Unverified"
    assert_text "Pending review"
    assert_link "Agent Integrations — API documentation & examples →", href: agent_integrations_path
    save_screenshot(directory.join("actual-inbox.png"))
    report[:steps] << { name: "Manager UI credential; separate Python actual POST201 then idempotent200; pending unverified inbox; no CRM creation", result: "PASS" }
    report[:result] = "PASS"
  ensure
    if report
      report[:finished_at] = Time.now.utc.iso8601
      FileUtils.mkdir_p(Rails.root.join(".local"))
      name = ".local/phase31-deterministic-#{report[:started_at].delete('^0-9')}.json"
      File.write(Rails.root.join(name), JSON.pretty_generate(report))
      File.write(Rails.root.join(".local/phase31-deterministic.json"), JSON.pretty_generate(report))
      puts JSON.generate(report.slice(:result, :groq_calls, :provider_tokens, :steps))
    end
  end
end
