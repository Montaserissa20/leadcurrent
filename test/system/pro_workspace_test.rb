require "application_system_test_case"

class ProWorkspaceTest < ApplicationSystemTestCase
  setup { @user = make_user }

  def sign_in
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.current_window.resize_to(1440, 1050)
    visit login_path
    page.execute_script("localStorage.setItem('leadcurrent-theme', 'light'); document.documentElement.dataset.theme = 'light'")
    fill_in "Email address", with: @user.email
    fill_in "Password", with: "test-password-123"
    click_button "Sign in →"
    assert_text "Make your next move count."
  end

  test "customer profile creates edits and completes task through real Turbo forms" do
    lead = make_lead(@user)
    sign_in
    visit lead_path(lead)
    assert_text "CUSTOMER 360°"
    find('summary', text: 'Create a task').click
    fill_in "Task title", with: "Prepare discovery questions"
    click_button "Create task"
    assert_text "Task created."
    within('.task-preview', text: 'Prepare discovery questions') { click_link "Edit" }
    fill_in "Task title", with: "Discuss customer priorities"
    click_button "Save task"
    assert_text "Task updated."
    within('.task-preview', text: 'Discuss customer priorities') { click_button "Complete" }
    assert_text "Follow-up task completed."
    assert_nil lead.reload.first_contact_at
    find('summary', text: 'Edit this lead').click
    fill_in "Record title", with: "Customer expansion"
    click_button "Save details"
    assert_text "Lead updated."
    assert_equal "Customer expansion", lead.reload.title
  end

  test "dashboard followup and next stage actions update recommendations immediately" do
    travel_to Time.zone.local(2026, 10, 15, 12)
    lead = qualify(make_lead(@user))
    task = ScheduleFollowUp.call(lead, actor: @user, due_at: 10.minutes.from_now)
    sign_in
    within('.recommendation') { click_button "Complete follow-up" }
    assert_text "Follow-up task completed."
    assert_no_selector '.recommendation'
    assert task.reload.completed_at
    deal = make_opportunity(@user)
    deal.update!(expected_closing_date: Date.current)
    visit root_path
    within('.recommendation') do
      select "Proposal", from: "Next stage"
      click_button "Move"
    end
    assert_current_path root_path
    assert_text "Opportunity moved to Proposal."
    assert_equal "proposal", deal.reload.status
  end

  test "analytics and command center remain usable in light dark and mobile" do
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [{ name: "prefers-reduced-motion", value: "reduce" }])
    make_lead(@user, created_at: 26.hours.ago)
    deal = make_opportunity(@user)
    deal.update!(value: 24000)
    sign_in
    assert_selector '.stage-progress', count: 5
    assert_selector 'html[data-theme=light]'
    FileUtils.mkdir_p(Rails.root.join('.local', 'upgrade-preview'))
    save_screenshot(Rails.root.join('.local', 'upgrade-preview', 'overview-light.png'))
    click_button "Toggle color theme"
    assert_selector 'html[data-theme=dark]'
    save_screenshot(Rails.root.join('.local', 'upgrade-preview', 'overview-dark.png'))
    within('.sidebar') { click_link "Analytics" }
    assert_text "See what moves your business."
    assert_selector '[data-metric=pipeline]', text: "$24,000"
    assert_selector '[data-metric=conversion]', text: "50.0%"
    save_screenshot(Rails.root.join('.local', 'upgrade-preview', 'analytics-desktop.png'))
    page.current_window.resize_to(390, 844)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
    assert page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')
    save_screenshot(Rails.root.join('.local', 'upgrade-preview', 'analytics-mobile.png'))
    visit root_path
    assert page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')
    assert_selector '.mobile-menu', visible: true
    save_screenshot(Rails.root.join('.local', 'upgrade-preview', 'overview-mobile.png'))
    visit opportunity_path(deal)
    assert_text "CUSTOMER 360°"
    assert page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')
    save_screenshot(Rails.root.join('.local', 'upgrade-preview', 'profile-mobile.png'))
  end
end
