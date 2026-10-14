require "test_helper"
require "capybara/rails"
require "selenium-webdriver"
Selenium::WebDriver.logger.level = :warn
Capybara.enable_aria_label = true
Capybara.register_driver :leadcurrent_browser do |app|
  browser = Gem.win_platform? ? :edge : :chrome
  options = browser == :edge ? Selenium::WebDriver::Edge::Options.new : Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--disable-gpu")
  options.add_argument("--no-sandbox")
  options.add_argument("--window-size=1440,1000")
  Capybara::Selenium::Driver.new(app, browser: browser, options: options)
end
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :leadcurrent_browser
end
