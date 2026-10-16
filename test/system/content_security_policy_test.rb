require "application_system_test_case"

class BrowserContentSecurityPolicyTest < ApplicationSystemTestCase
  test "Stimulus initializes on a fresh anonymous page and survives Turbo navigation" do
    page.driver.browser.manage.delete_all_cookies
    visit login_path
    assert_selector 'html[data-theme]'
    click_link "Create a workspace"
    assert_text "Start your next chapter."
    assert_selector 'html[data-theme]'
  end
end
