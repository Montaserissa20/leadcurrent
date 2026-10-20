# Explicit live check only; never loaded by the normal suite or GitHub CI.
# Run: LEADCURRENT_LIVE_AI=1 bundle exec ruby script/verify_groq.rb
abort "Live Groq verification is opt-in: set LEADCURRENT_LIVE_AI=1." unless ENV["LEADCURRENT_LIVE_AI"] == "1"
abort "Live verification is not permitted in CI or production." if ENV["CI"] || (ENV["RAILS_ENV"] && ENV["RAILS_ENV"] != "test")
abort "GROQ_API_KEY is missing; no live call was made." if ENV.fetch("GROQ_API_KEY", "").strip.empty?
ENV["RAILS_ENV"] = "test"
$LOAD_PATH.unshift(File.expand_path("../test", __dir__))
require_relative "../test/application_system_test_case"
require "json"
require "fileutils"
require "digest"

class LiveGroqSalesAssistantCheck < ApplicationSystemTestCase
  test "real browser receives all four real Groq answers for a fictional PostgreSQL customer" do
    report = { started_at: Time.now.utc.iso8601, environment: "local test PostgreSQL + real Groq + headless browser",
      mocked: false, result: "FAIL", calls: [], human_effort: "not measured", coding_agent_tokens: "not measured", paid_cost: "not measured" }
    files = Dir["app/services/ai/*.rb", "app/controllers/ai/*.rb", "app/views/ai/**/*.erb", "app/views/ai/*.erb", "app/javascript/controllers/ai_sales_controller.js", "app/assets/stylesheets/ai.css"].uniq.sort
    report[:implementation_sha256] = Digest::SHA256.hexdigest(files.map { |path| path + File.binread(path) }.join)
    previous_wait = Capybara.default_max_wait_time
    Capybara.default_max_wait_time = 35
    user = make_user(role: "salesperson")
    lead = make_lead(user)
    lead.update!(title: "Fictional Atlas 40-seat subscription", notes: "Fictional verification customer: interested in 40 software seats. A budget of 9000 USD was recorded but is not approved. Procurement/security review and decision-maker remain unknown.")
    RecordActivity.call(lead, actor: user, kind: "note", body: "Customer asked for annual subscription pricing. No meeting or purchase commitment was recorded.")
    ScheduleFollowUp.call(lead, actor: user, due_at: 4.hours.from_now, title: "Confirm seats and procurement requirements")
    original = { lead: lead.reload.attributes, tasks: lead.tasks.order(:id).map(&:attributes), activities: lead.activities.order(:id).map(&:attributes), audit_count: AuditEvent.count }
    metrics = []
    subscription = ActiveSupport::Notifications.subscribe("completion.ai") { |_name, _start, _finish, _id, payload| metrics << payload.slice(:model, :usage) }
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.current_window.resize_to(1440, 1050)
    visit login_path
    fill_in "Email address", with: user.email
    fill_in "Password", with: "test-password-123"
    click_button "Sign in →"
    assert_text "Make your next move count."
    visit lead_path(lead)
    assert_text "LeadCurrent AI"
    Ai::SalesAdvisor::MODES.each_with_index do |(mode, label), index|
      # Space requests to respect the documented free-tier per-minute token budget.
      sleep 25 if index.positive?
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      within(".ai-panel") do
        fill_in "Ask about this customer (optional)", with: "Use only this fictional customer's records; explain facts and unknowns."
        click_button label
        assert_selector ".ai-answer h3", text: label
        assert_no_selector ".ai-error"
      end
      assert metrics.size == index + 1, "Expected one genuine provider completion per action"
      assert !page.html.include?(ENV.fetch("GROQ_API_KEY")), "Credential must never appear in HTML"
      assert_current_path lead_path(lead)
      assert_equal "new", lead.reload.status
      report[:calls] << { mode: mode, result: "PASS", elapsed_seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(3),
        model: metrics.last[:model], usage: metrics.last[:usage],
        summary: page.find(".ai-answer .ai-prose", match: :first).text,
        next_step: page.all(".ai-answer .ai-prose")[1].text,
        draft_present: page.has_selector?(".ai-draft", wait: 0) }
      if index.zero?
        FileUtils.mkdir_p(Rails.root.join(".local", "ai-preview"))
        page.find(".ai-panel").scroll_to(:top)
        save_screenshot(Rails.root.join(".local", "ai-preview", "analysis-live-desktop.png"))
      end
      puts JSON.generate(report[:calls].last.slice(:mode, :result, :elapsed_seconds, :model, :usage))
    end
    assert_equal original, { lead: lead.reload.attributes, tasks: lead.tasks.order(:id).map(&:attributes), activities: lead.activities.order(:id).map(&:attributes), audit_count: AuditEvent.count }
    report[:database_unchanged_by_ai] = true
    report[:result] = "PASS"
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription) if subscription
    Capybara.default_max_wait_time = previous_wait if previous_wait
    if report
      report[:provider_completions] = metrics if metrics
      report[:finished_at] = Time.now.utc.iso8601
      FileUtils.mkdir_p(Rails.root.join(".local"))
      File.write(Rails.root.join(".local", "ai-live-verification.json"), JSON.pretty_generate(report))
      puts JSON.generate(report.slice(:result, :started_at, :finished_at, :database_unchanged_by_ai))
    end
  end
end
