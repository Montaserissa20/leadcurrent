require "application_system_test_case"
class SalesWorkflowTest < ApplicationSystemTestCase
  setup { @user = make_user }
  def sign_in
    page.current_window.resize_to(1440, 1000)
    visit login_path
    fill_in "Email address", with: @user.email
    fill_in "Password", with: "test-password-123"
    click_button "Sign in →"
    assert_text "Make your next move count."
  end
  test "browser completes lead to won flow with Turbo and persistent dashboard" do
    sign_in
    within('.topbar') { click_link "+ New lead" }
    fill_in "Lead title", with: "Atlas annual subscription"
    fill_in "Company name", with: "Atlas Industries"
    fill_in "Contact name", with: "Sam Taylor"
    fill_in "Contact email", with: "sam@example.test"
    click_button "Create lead"
    assert_text "First contact is due within 24 hours."
    fill_in "What happened?", with: "Completed discovery call"
    click_button "Save action"
    assert_text "Contact recorded. Follow-up scheduled."
    click_button "Mark qualified"
    assert_text "Lead moved to Qualified."
    fill_in "Opportunity title", with: "Atlas annual subscription"
    fill_in "Value", with: "18000"
    click_button "Convert lead"
    assert_text "Lead converted to an opportunity."
    %w[Proposal Negotiation Won].each do |stage|
      select stage, from: "Next stage"
      click_button "Move"
      assert_text "Opportunity moved to #{stage}."
    end
    within('.sidebar') { click_link "Overview" }
    assert_selector '[data-stat="won_value"]', text: "$18,000"
    assert_selector '[data-stat="active_opportunities"] strong', text: "0"
    page.refresh
    assert_selector '[data-stat="won_value"]', text: "$18,000"
    assert_equal "won", @user.organization.opportunities.last.status
  end
  test "dashboard completes contact plus followup with one submit and theme and mobile work" do
    lead = make_lead(@user, created_at: 25.hours.ago)
    sign_in
    within('.recommendation') do
      fill_in "What happened?", with: "Completed customer call"
      click_button "Save action"
    end
    assert_text "Contact recorded. Follow-up scheduled."
    assert_no_selector '.recommendation'
    assert_equal "contacted", lead.reload.status
    assert_equal 1, lead.tasks.pending.count
    before = page.evaluate_script('document.documentElement.dataset.theme')
    click_button "Toggle color theme"
    assert_not_equal before, page.evaluate_script('document.documentElement.dataset.theme')
    page.refresh
    assert_not_equal before, page.evaluate_script('document.documentElement.dataset.theme')
    page.current_window.resize_to(390, 844)
    assert_selector '.mobile-menu', visible: true
    click_button "Toggle navigation"
    assert_selector '#sidebar.open'
    within('#sidebar') { click_link "Leads" }
    assert_text "Start the conversation."
    assert page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')
  end
end
