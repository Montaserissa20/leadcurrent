require "application_system_test_case"

class AgentIntegrationsBrowserTest < ApplicationSystemTestCase
  test "public developer page has keyboard examples working clipboard downloads and responsive themes" do
    visit agent_integrations_path
    assert_selector "h1", text: "Agent Integrations"
    assert_selector 'a[href="#integration-content"]', text: "Skip to integration guide", visible: :all
    assert_selector '.integration-flow li', count: 6
    assert_no_selector '[data-controller="page-agent"]'
    origin = page.evaluate_script("location.origin")
    page.driver.browser.execute_cdp("Browser.grantPermissions", origin: origin, permissions: ["clipboardReadWrite", "clipboardSanitizedWrite"])
    click_button "Copy API endpoint"
    assert_text "Copied. Configure your private credential"
    assert_equal origin + api_v1_agent_inquiries_path, page.evaluate_async_script("const done=arguments[0];navigator.clipboard.readText().then(done)")
    %w[curl powershell python].each do |language|
      code = find("#example-#{language}", visible: :all)
      details = code.find(:xpath, "ancestor::details")
      summary = details.find("summary")
      unless details.evaluate_script("this.open")
        summary.send_keys(:space)
      end
      assert code.visible?
      details.find("button").click
      assert_text "Copied. Configure your private credential"
      actual = page.evaluate_async_script("const done=arguments[0];navigator.clipboard.readText().then(done)")
      assert_equal code.evaluate_script("this.textContent"), actual.gsub("\r\n", "\n")
    end
    assert_button "Copy example", count: 3, wait: 4
    assert_link "Download OpenAPI specification", href: agent_inquiries_openapi_path
    assert_link "Manage Agent Credentials →", href: agent_credentials_path
    assert_link "View Agent Inquiries →", href: agent_inquiries_path
    page.driver.browser.manage.window.resize_to(390, 844)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
    assert_equal 390, page.evaluate_script("window.innerWidth")
    %w[light dark].each do |theme|
      page.execute_script("document.documentElement.dataset.theme=arguments[0]", theme)
      assert_equal theme, page.evaluate_script("document.documentElement.dataset.theme")
      assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth"), "No page overflow at phone width"
    end
    click_button "Toggle color theme"
    assert_equal "light", page.evaluate_script("document.documentElement.dataset.theme")
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.manage.window.resize_to(1440, 1000)
  end

  test "clipboard denial explains manual copy and public documents do not reveal workspace records" do
    visit agent_integrations_path
    page.execute_script("Object.defineProperty(navigator.clipboard, 'writeText', {value: () => Promise.reject(new Error('denied')), configurable:true})")
    click_button "Copy API endpoint"
    assert_text "Clipboard unavailable. Example selected; press Ctrl+C or Command+C to copy."
    assert_equal find("#integration-endpoint").text, page.evaluate_script("window.getSelection().toString()")
    click_link "Manage Agent Credentials →"
    assert_current_path login_path
  end
end
