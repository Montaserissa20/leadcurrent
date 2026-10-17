require "application_system_test_case"

class PasswordManagementSystemTest < ApplicationSystemTestCase
  setup do
    @manager = make_user
    @manager_replacement, @temporary, @member_replacement = Array.new(3) { SecureRandom.base64(24) }
    PasswordsController::RATE_LIMIT_STORE.clear
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.current_window.resize_to(1440, 1050)
  end

  def sign_in(email, password)
    visit login_path
    fill_in "Email address", with: email
    fill_in "Password", with: password
    click_button "Sign in →"
  end

  def fill_password_form(current, replacement, confirmation: replacement)
    fill_in "Current password", with: current
    fill_in "New password", with: replacement, exact: true
    fill_in "Confirm new password", with: confirmation
  end

  test "manager changes password and a new salesperson replaces the temporary password before CRM access" do
    sign_in(@manager.email, "test-password-123")
    assert_text "Make your next move count."
    within(".sidebar") { click_link "Settings & team" }
    assert_text "Security & Password"
    within(".password-section") do
      fill_password_form("test-password-123", @manager_replacement)
      click_button "Show current password"
      assert_selector 'input[name="password_change[current_password]"][type=text]'
      click_button "Hide current password"
      assert_selector 'input[name="password_change[current_password]"][type=password]'
      click_button "Change password"
    end
    assert_text "Password changed. Your other sessions have been signed out."
    assert_current_path settings_path
    click_button "Sign out"
    sign_in(@manager.email, "test-password-123")
    assert_text "Email or password is incorrect."
    sign_in(@manager.email, @manager_replacement)
    assert_text "Make your next move count."
    visit settings_path
    within("form[action='#{team_members_path}']") do
      fill_in "Name", with: "New colleague"
      fill_in "Email", with: "new-colleague@example.test"
      fill_in "Temporary password (12+ characters)", with: @temporary
      click_button "Add team member"
    end
    assert_text "Team member added."
    member = User.find_by!(email: "new-colleague@example.test")
    assert member.password_change_required?
    click_button "Sign out"
    sign_in(member.email, @temporary)
    assert_current_path edit_password_path
    assert_text "Replace your temporary password to unlock your workspace."
    visit leads_path
    assert_current_path edit_password_path
    fill_password_form(@temporary, @member_replacement)
    click_button "Change password"
    assert_text "Password changed."
    assert_not member.reload.password_change_required?
    visit root_path
    assert_text "Make your next move count."
    click_button "Sign out"
    sign_in(member.email, @temporary)
    assert_text "Email or password is incorrect."
    sign_in(member.email, @member_replacement)
    assert_text "Make your next move count."
  end

  test "validation clears all secret fields and the password form works on mobile and both themes" do
    sign_in(@manager.email, "test-password-123")
    assert_text "Make your next move count."
    visit settings_path
    within(".password-section") do
      fill_password_form("incorrect-secret-123", @manager_replacement)
      click_button "Change password"
    end
    assert_text "Current password is incorrect"
    assert_selector 'input[type=password]', count: 3
    all('input[type=password]').each { |field| assert_equal "", field.value }
    assert_no_selector 'input[type=password][value]'
    %w[light dark].each do |theme|
      page.execute_script("localStorage.setItem('leadcurrent-theme', arguments[0]); document.documentElement.dataset.theme = arguments[0]", theme)
      page.current_window.resize_to(390, 844)
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
      assert_selector "html[data-theme=#{theme}]"
      assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")
      %w[current_password password password_confirmation].each do |attribute|
        assert find("input[name='password_change[#{attribute}]']").visible?
      end
    end
    fill_password_form("test-password-123", @manager_replacement)
    click_button "Show new password"
    assert_selector 'input[name="password_change[password]"][type=text]'
    click_button "Hide new password"
    click_button "Show confirm new password"
    assert_selector 'input[name="password_change[password_confirmation]"][type=text]'
    click_button "Hide confirm new password"
    click_button "Change password"
    assert_text "Password changed."
  end
end
