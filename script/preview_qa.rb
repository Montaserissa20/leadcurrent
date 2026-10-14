require "selenium-webdriver"
require "fileutils"
Selenium::WebDriver.logger.level = :warn
options = Selenium::WebDriver::Edge::Options.new
%w[--headless=new --disable-gpu --no-sandbox --window-size=1440,1100].each { |arg| options.add_argument(arg) }
driver = Selenium::WebDriver.for(:edge, options: options)
wait = Selenium::WebDriver::Wait.new(timeout: 10)
begin
  driver.get("http://127.0.0.1:3100/login")
  driver.find_element(id: "email").send_keys("demo@leadcurrent.test")
  driver.find_element(id: "password").send_keys("LeadCurrentDemo!2026")
  driver.find_element(css: "input[type=submit]").click
  wait.until { driver.find_elements(css: ".stats-grid").any? }
  driver.execute_script("localStorage.setItem('leadcurrent-theme', 'light'); document.documentElement.dataset.theme = 'light'")
  FileUtils.mkdir_p("docs/screenshots")
  driver.save_screenshot("docs/screenshots/dashboard-light.png")
  driver.get("http://127.0.0.1:3100/pipeline")
  wait.until { driver.find_elements(css: ".kanban").any? }
  driver.save_screenshot("docs/screenshots/pipeline-light.png")
  driver.get("http://127.0.0.1:3100/")
  driver.manage.window.resize_to(390, 844)
  driver.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
  wait.until { driver.find_element(css: ".mobile-menu").displayed? }
  wait.until { driver.execute_script("return document.getElementById('sidebar').getBoundingClientRect().right <= 0.5") }
  driver.save_screenshot("docs/screenshots/dashboard-mobile.png")
  raise "Mobile overflow" unless driver.execute_script("return document.documentElement.scrollWidth <= window.innerWidth")
  raise "Wrong mobile width" unless driver.execute_script("return window.innerWidth") == 390
  puts "Real seeded workspace screenshots captured; desktop, pipeline and 390px mobile render verified."
ensure
  driver.quit
end
