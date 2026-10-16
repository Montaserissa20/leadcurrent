require "application_system_test_case"

class AdaptationInteractionTest < ApplicationSystemTestCase
  test "one dashboard submission records completed contact and the next followup" do
    user = make_user
    lead = make_lead(user, created_at: 25.hours.ago)
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.current_window.resize_to(1440, 1000)
    visit login_path
    fill_in "Email address", with: user.email
    fill_in "Password", with: "test-password-123"
    click_button "Sign in →"
    assert_text "Make your next move count."

    # Measure only the interaction after login, with tomorrow's default followup.
    page.execute_script <<~JS
      sessionStorage.setItem('adaptation-clicks', '0');
      sessionStorage.setItem('adaptation-submits', '0');
      document.querySelector('.recommendation .action-form').addEventListener('click', () => {
        sessionStorage.setItem('adaptation-clicks', Number(sessionStorage.getItem('adaptation-clicks')) + 1);
      });
      document.querySelector('.recommendation .action-form').addEventListener('submit', () => {
        sessionStorage.setItem('adaptation-submits', Number(sessionStorage.getItem('adaptation-submits')) + 1);
      });
    JS
    action_posts = 0
    profile_visits = 0
    subscriber = lambda do |_name, _start, _finish, _id, payload|
      action_posts += 1 if payload[:controller] == "ActionsController" && payload[:action] == "create" && payload[:method] == "POST"
      profile_visits += 1 if payload[:controller] == "LeadsController" && payload[:action] == "show"
    end
    ActiveSupport::Notifications.subscribed(subscriber, "process_action.action_controller") do
      within(".recommendation") do
        field = find_field("What happened?")
        field.click
        field.send_keys("Completed customer call")
        click_button "Save action"
      end
      assert_text "Contact recorded. Follow-up scheduled."
      assert_no_selector ".recommendation"
    end

    assert_current_path root_path
    assert_equal 2, page.evaluate_script("Number(sessionStorage.getItem('adaptation-clicks'))")
    assert_equal 1, page.evaluate_script("Number(sessionStorage.getItem('adaptation-submits'))")
    assert_equal 1, action_posts
    assert_equal 0, profile_visits
    assert_equal "contacted", lead.reload.status
    assert lead.first_contact_at
    assert_equal 1, lead.activities.where(kind: "contact").count
    assert_equal 1, lead.tasks.pending.count
  end
end
