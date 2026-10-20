require "application_system_test_case"
require_relative "../support/ai_test_support"

class AiSalesAssistantTest < ApplicationSystemTestCase
  include AiTestSupport
  setup do
    install_fake_groq
    @user = make_user(role: "salesperson")
    @lead = make_lead(@user)
    @lead.update!(notes: "Interested in subscriptions for 40 seats; budget is not confirmed.")
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.current_window.resize_to(1440, 1050)
  end
  teardown { restore_fake_groq }

  def sign_in
    visit login_path
    fill_in "Email address", with: @user.email
    fill_in "Password", with: "test-password-123"
    click_button "Sign in →"
    assert_text "Make your next move count."
  end

  test "salesperson uses all four Groq-backed controls with loading duplicate prevention and copy" do
    sign_in
    visit lead_path(@lead)
    assert_text "LeadCurrent AI"
    @ai_delay = 0.8
    within(".ai-panel") do
      fill_in "Ask about this customer (optional)", with: "Analyze this customer and explain the next step."
      click_button "Analyze customer"
      assert_selector ".ai-loading", visible: true
      assert_selector ".ai-actions button:disabled", count: 4
      page.execute_script("document.querySelector('.ai-panel form').requestSubmit(document.querySelector('.ai-actions button'))")
      assert_selector ".ai-answer"
      assert_text "AI-GENERATED"
      assert_text "Priority 50"
      assert_no_selector ".ai-loading", visible: true
      assert_equal 1, @ai_requests.size
      assert_selector ".ai-actions button:enabled", count: 4
      assert_equal "Analyze this customer and explain the next step.", find_field("Ask about this customer (optional)").value
      click_button "What should I do next?"
      assert_selector ".ai-answer h3", text: "What should I do next?"
      click_button "Summarize activities"
      assert_selector ".ai-answer h3", text: "Summarize activities"
      assert_text "No recorded activity history for this customer."
      click_button "Draft follow-up"
      assert_selector ".ai-draft", text: "Hello Atlas Industries"
      page.execute_script("window.aiCopied = ''; Object.defineProperty(navigator, 'clipboard', { configurable: true, value: { writeText: async text => { window.aiCopied = text } } })")
      click_button "Copy draft"
      assert_text "Copied for review."
      assert_match "Hello Atlas Industries", page.evaluate_script("window.aiCopied")
    end
    assert_current_path lead_path(@lead)
    assert_equal "new", @lead.reload.status
    assert_equal 4, @ai_requests.size
    assert_equal 0, @lead.activities.count
    assert_equal 0, @lead.tasks.count
    page.execute_script("document.dispatchEvent(new Event('turbo:before-cache'))")
    assert_equal "", find_field("Ask about this customer (optional)").value
    assert_no_selector ".ai-answer"
  end

  test "manager opportunity panel stays on the customer page for provider errors and safely renders text on mobile" do
    @user.update!(role: "manager")
    opportunity = make_opportunity(@user)
    sign_in
    visit opportunity_path(opportunity)
    ENV.delete("GROQ_API_KEY")
    within(".ai-panel") { click_button "Analyze customer" }
    assert_selector ".ai-error", text: "not configured"
    assert_current_path opportunity_path(opportunity)
    assert_text "CUSTOMER 360°"
    ENV["GROQ_API_KEY"] = @ai_api_key
    @ai_answer = { summary: '<script>window.aiInjected = true</script>', evidence_ids: %w[record], risks: [], next_step: "Review manually", explanation: "Use only recorded facts", assumptions: [], draft: "" }
    within(".ai-panel") { click_button "Analyze customer" }
    assert_selector ".ai-answer"
    assert_text '<script>window.aiInjected = true</script>'
    assert_no_selector ".ai-answer script"
    assert_not page.evaluate_script("Boolean(window.aiInjected)")
    assert_not_includes page.html, @ai_api_key
    page.current_window.resize_to(390, 844)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
    %w[light dark].each do |theme|
      page.execute_script("document.documentElement.dataset.theme = arguments[0]", theme)
      assert_selector "html[data-theme=#{theme}]"
      assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")
      assert_selector ".ai-actions button", count: 4
      assert find_field("Ask about this customer (optional)").visible?
    end
    @ai_status = 429
    within(".ai-panel") { click_button "Summarize activities" }
    assert_selector ".ai-error", text: "limit reached"
    assert_current_path opportunity_path(opportunity)
    assert_selector ".ai-actions button:enabled", count: 4
  end
end
