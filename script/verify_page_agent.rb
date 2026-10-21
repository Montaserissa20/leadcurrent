# Opt-in real PageAgentCore + real Groq + real browser demonstration. Fictional test data rolls back.
abort "Set LEADCURRENT_LIVE_AGENT=1 to opt in." unless ENV["LEADCURRENT_LIVE_AGENT"] == "1"
abort "Live checks are local-test only." if ENV["CI"] || (ENV["RAILS_ENV"] && ENV["RAILS_ENV"] != "test")
abort "GROQ_API_KEY is missing. No real browser/provider request was made." if ENV.fetch("GROQ_API_KEY", "").strip.empty?
ENV["RAILS_ENV"] = "test"
$LOAD_PATH.unshift(File.expand_path("../test", __dir__))
require_relative "../test/application_system_test_case"
require "json"
require "fileutils"

class LivePageAgentCheck < ApplicationSystemTestCase
  test "genuine Page Agent finds overdue Atlas and prepares a note without submitting" do
    report = { started_at: Time.now.utc.iso8601, mocked: false, environment: "local test PostgreSQL + real Groq + official Page Agent + browser", result: "FAIL", scenarios: [], provider_completions: [], human_effort: "not measured", coding_agent_tokens: "not measured", paid_cost: "not measured" }
    previous = Capybara.default_max_wait_time
    Capybara.default_max_wait_time = 20
    user = make_user(role: "salesperson")
    lead = make_lead(user, created_at: 28.hours.ago)
    lead.update!(title: "Fictional Atlas 40-seat subscription", notes: "PRIVATE_HISTORY: fictional budget not approved. Never send this sensitive note to the browser agent provider.")
    colleague = make_user(organization: user.organization, role: "salesperson")
    other_lead = make_lead(colleague, created_at: 32.hours.ago)
    other_lead.update!(title: "Fictional colleague-owned overdue customer")
    original = { lead: lead.reload.attributes, tasks: lead.tasks.map(&:attributes), activities: lead.activities.map(&:attributes), audits: AuditEvent.count }
    subscription = ActiveSupport::Notifications.subscribe(/\Acompletion\.(page_agent|copilot)\z/) { |name, _start, _finish, _id, payload| report[:provider_completions] << payload.slice(:model,:usage,:action,:duration_seconds).merge(surface:name) }
    failure_subscription = ActiveSupport::Notifications.subscribe("failure.page_agent") { |_name, _start, _finish, _id, payload| (report[:provider_failures] ||= []) << payload.slice(:status,:code) }
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.current_window.resize_to(1440,1050)
    visit login_path
    fill_in "Email address",with:user.email
    fill_in "Password",with:"test-password-123"
    click_button "Sign in →"
    assert_text "Make your next move count."
    page.execute_script("window.agentCspViolations=0;window.agentNavigation=[];document.addEventListener('securitypolicyviolation',()=>window.agentCspViolations++);document.addEventListener('turbo:load',()=>window.agentNavigation.push({path:location.pathname,attention:new URLSearchParams(location.search).get('attention')}))")
    click_button "AI Agent"
    ["Find my overdue leads.","Open Atlas Industries.","Prepare a follow-up note for this customer."].each_with_index do |task,index|
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      within("#agent-panel") { fill_in "What would you like to do?",with:task;click_button "Run" }
      assert_selector "#leadcurrent-agent[data-status=completed], #leadcurrent-agent[data-status=failed]",wait:180
      assert_selector "#leadcurrent-agent[data-status=completed]",wait:0
      assert_selector ".agent-steps li",visible: :all
      if index.zero?
        assert_current_path leads_path,ignore_query:true
        assert_equal "overdue",page.find('select[name=attention]').value
        assert_equal user.id.to_s,page.find('select[name=owner_id]').value
        assert_no_selector "tbody a[href='#{lead_path(other_lead)}']"
      elsif index == 1
        assert_current_path lead_path(lead)
      else
        assert_current_path lead_path(lead)
        assert_equal "note",page.find('select[name=action_kind]').value
        assert find_field("What happened?").value.present?
        assert_equal "",find_field("Next follow-up (optional)").value
      end
      assert_equal original,{lead:lead.reload.attributes,tasks:lead.tasks.map(&:attributes),activities:lead.activities.map(&:attributes),audits:AuditEvent.count}
      assert_equal 0,page.evaluate_script("window.agentCspViolations || 0")
      assert !page.html.include?(ENV.fetch("GROQ_API_KEY")),"Credential must not appear in HTML"
      report[:scenarios] << {task:task,result:"PASS",page_path:page.current_path,executed_steps:page.all('.agent-steps li',visible: :all).size,activity:page.all('.agent-steps li',visible: :all).map(&:text),elapsed_seconds:(Process.clock_gettime(Process::CLOCK_MONOTONIC)-started).round(3),crm_unchanged:true,own_records_filtered:index.zero? ? true : nil}
      puts JSON.generate(report[:scenarios].last)
    end
    assert report[:provider_completions].any?,"Expected actual provider completions"
    # Separate test-user interaction after the AI task ended; never an agent tool submission.
    click_button "Save action"
    assert_text "Note recorded."
    assert_equal ["note"],lead.reload.activities.pluck(:kind)
    assert_nil lead.reload.first_contact_at
    assert_equal "new",lead.status
    assert_equal 0,lead.tasks.count
    report[:separate_user_submit] = "PASS: note only; no first contact or task"
    report[:result] = "PASS"
    FileUtils.mkdir_p(Rails.root.join('.local','page-agent-preview'))
    save_screenshot(Rails.root.join('.local','page-agent-preview','real-agent-completed.png'))
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription) if subscription
    ActiveSupport::Notifications.unsubscribe(failure_subscription) if failure_subscription
    Capybara.default_max_wait_time = previous if previous
    if report
      report[:finished_at] = Time.now.utc.iso8601
      report[:navigation] = page.evaluate_script('window.agentNavigation || []') rescue []
      report[:csp_violations] = page.evaluate_script('window.agentCspViolations || 0') rescue nil
      report[:diagnostic] = page.evaluate_script("(()=>{const c=window.Stimulus?.getControllerForElementAndIdentifier(document.getElementById('leadcurrent-agent'),'page-agent');return {failureCode:c?.failureCode||null,proxyErrorCode:c?.proxyErrorCode||null,lastAttempt:c?.lastAttempt||null}})()") rescue nil
      FileUtils.mkdir_p(Rails.root.join('.local'))
      File.write(Rails.root.join('.local','page-agent-live.json'),JSON.pretty_generate(report))
      puts JSON.generate(report.slice(:result,:started_at,:finished_at,:separate_user_submit))
    end
  end
end
