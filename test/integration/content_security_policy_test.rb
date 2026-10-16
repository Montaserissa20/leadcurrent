require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  test "fresh anonymous requests authorize importmap scripts and Turbo styles with a nonempty nonce" do
    get login_path
    assert_response :success
    policy = response.headers.fetch("content-security-policy")
    nonce = Nokogiri::HTML(response.body).at_css('meta[name="csp-nonce"]')&.[]("content")
    assert nonce.present?, "A fresh anonymous page must have a nonempty CSP nonce"
    %w[script-src style-src].each do |directive|
      sources = policy.split(";").map(&:strip).find { |value| value.start_with?("#{directive} ") }
      assert sources.include?("'nonce-#{nonce}'"), "#{directive} must authorize the emitted nonce"
      assert_not sources.include?("'unsafe-inline'"), "Do not weaken inline protection"
    end
    scripts = Nokogiri::HTML(response.body).css('script[type="importmap"], script[type="module"]')
    assert scripts.any?
    assert scripts.all? { |script| script["nonce"] == nonce }, "Inline importmap/module tags must match the CSP"
    get signup_path
    next_nonce = Nokogiri::HTML(response.body).at_css('meta[name="csp-nonce"]')["content"]
    assert nonce == next_nonce, "Keep the nonce stable across Turbo navigation in the same session"
    other = open_session
    other.get login_path
    other_nonce = Nokogiri::HTML(other.response.body).at_css('meta[name="csp-nonce"]')["content"]
    assert nonce != other_nonce, "Independent browser sessions must not share a nonce"
  end
end
