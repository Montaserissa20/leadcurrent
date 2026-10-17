require "test_helper"

class PasswordManagementTest < ActionDispatch::IntegrationTest
  NEW_PASSWORD = SecureRandom.base64(24)
  setup do
    @user = make_user
    PasswordsController::RATE_LIMIT_STORE.clear
  end

  def change_password(client = self, **values)
    client.patch password_path, params: { password_change: {
      current_password: "test-password-123", password: NEW_PASSWORD, password_confirmation: NEW_PASSWORD
    }.merge(values) }
  end

  test "both roles can replace their own password with a rotated session and no profile changes" do
    %w[manager salesperson].each do |role|
      user = make_user(role: role)
      login(user)
      old_session = Session.where(user: user).sole
      old_cookie = cookies[Rails.application.config.session_options[:key]]
      digest = user.password_digest
      get settings_path
      assert_select "#security-heading", text: "Security & Password"
      assert_select 'input[type=password]', minimum: 3

      change_password
      assert_redirected_to settings_path
      assert_match "Password changed", flash[:notice]
      assert_not_equal digest, user.reload.password_digest
      assert_not user.authenticate("test-password-123")
      assert user.authenticate(NEW_PASSWORD)
      assert_equal role, user.role
      assert_equal "Alex Morgan", user.name
      replacement = Session.where(user: user).sole
      assert_not_equal old_session.id, replacement.id
      assert_equal old_session.expires_at, replacement.expires_at
      assert_not_equal old_cookie, cookies[Rails.application.config.session_options[:key]]
      get root_path
      assert_response :success
      delete logout_path
      post login_path, params: { email: user.email, password: "test-password-123" }
      assert_response :unprocessable_entity
      post login_path, params: { email: user.email, password: NEW_PASSWORD }
      assert_redirected_to root_path
    end
  end

  test "invalid changes preserve digest sessions temporary flag and audit and never echo passwords" do
    @user.update!(password_change_required: true)
    post login_path, params: { email: @user.email, password: "test-password-123" }
    assert_redirected_to edit_password_path
    digest = @user.reload.password_digest
    session_ids = Session.where(user: @user).pluck(:id)
    cases = [
      [{ current_password: "wrong-current-secret" }, /Current password is incorrect/],
      [{ password: "short", password_confirmation: "short" }, /too short/],
      [{ password_confirmation: "mismatched-secret" }, /doesn't match/],
      [{ password: "test-password-123", password_confirmation: "test-password-123" }, /must be different/],
      [{ password: "", password_confirmation: "" }, /can't be blank/],
      [{ password_confirmation: "" }, /confirmation can't be blank/i],
      [{ password: "z" * 73, password_confirmation: "z" * 73 }, /too long/]
    ]
    cases.each do |values, message|
      PasswordsController::RATE_LIMIT_STORE.clear
      assert_no_difference("AuditEvent.count") { change_password(**values) }
      assert_response :unprocessable_entity
      assert_select '[role=alert]', text: message
      assert_equal digest, @user.reload.password_digest
      assert @user.password_change_required?
      assert_select 'nav[aria-label="Main navigation"]', count: 0
      assert_equal session_ids, Session.where(user: @user).pluck(:id)
      assert_select 'input[type=password][value]', count: 0
      [NEW_PASSWORD, "wrong-current-secret", "mismatched-secret", "test-password-123"].each { |secret| assert_not_includes response.body, secret }
      assert_equal "no-store", response.headers["Cache-Control"]
    end
  end

  test "changing password revokes other sessions and replayed cookies while preserving other users" do
    login(@user)
    old_cookie = cookies[Rails.application.config.session_options[:key]]
    other = open_session
    other.post login_path, params: { email: @user.email, password: "test-password-123" }
    teammate = make_user(organization: @user.organization)
    unrelated_session = Session.create!(user: teammate, expires_at: 12.hours.from_now)
    change_password
    assert_redirected_to settings_path
    assert_equal 1, Session.where(user: @user).count
    assert Session.exists?(unrelated_session.id)
    other.get root_path
    other.assert_redirected_to login_path
    replay = open_session
    replay.cookies[Rails.application.config.session_options[:key]] = old_cookie
    replay.get settings_path
    replay.assert_redirected_to login_path
    get root_path
    assert_response :success
    event = AuditEvent.where(actor: @user, action: "password_changed").sole
    assert_equal({ "other_sessions_revoked" => 1 }, event.details)
    assert_not_includes event.details.to_json, NEW_PASSWORD
  end

  test "anonymous direct requests cannot change passwords" do
    get edit_password_path
    assert_redirected_to login_path
    digest = @user.password_digest
    change_password
    assert_redirected_to login_path
    assert_equal digest, @user.reload.password_digest
  end

  test "manager cannot target another user or workspace with password requests" do
    login(@user)
    others = [make_user(organization: @user.organization, role: "salesperson"), make_user]
    others.each do |other|
      digest = other.password_digest
      change_password(user_id: other.id)
      assert_response :unprocessable_entity
      assert_select '[role=alert]', text: /Only your own password/
      assert_equal digest, other.reload.password_digest
      assert @user.reload.authenticate("test-password-123")
    end
    patch password_path, params: { user_id: others.first.id, password_change: { current_password: "test-password-123", password: NEW_PASSWORD, password_confirmation: NEW_PASSWORD } }
    assert_response :unprocessable_entity
    patch "#{password_path}/#{others.first.id}", params: {}
    assert_response :not_found
  end

  test "new salesperson must change temporary password before direct CRM requests but can log out" do
    temporary = SecureRandom.base64(24)
    login(@user)
    existing = make_user(organization: @user.organization, role: "salesperson")
    assert_not existing.password_change_required?
    post team_members_path, params: { user: { name: "New salesperson", email: "temporary@example.test", password: temporary, password_change_required: false, role: "manager" } }
    assert_redirected_to settings_path
    member = User.find_by!(email: "temporary@example.test")
    assert member.password_change_required?
    assert_equal "salesperson", member.role
    assert_not @user.reload.password_change_required?
    delete logout_path
    post login_path, params: { email: member.email, password: temporary }
    assert_redirected_to edit_password_path
    get edit_password_path
    assert_response :success
    assert_select 'nav[aria-label="Main navigation"]', count: 0
    assert_select "form[action='#{logout_path}']", count: 1
    [root_path, settings_path, leads_path, opportunities_path, pipeline_path, analytics_path, tasks_path, activity_path, signup_path].each do |path|
      get path
      assert_redirected_to edit_password_path
    end
    assert_no_difference(["Lead.count", "User.count", "Organization.count"]) do
      post leads_path, params: { lead: { title: "Bypass attempt" } }
      assert_redirected_to edit_password_path
      post team_members_path, params: { user: { name: "Bypass" } }
      assert_redirected_to edit_password_path
      post signup_path, params: { workspace_name: "Bypass" }
      assert_redirected_to edit_password_path
      patch settings_path, params: { user: { password_change_required: false, name: "Bypass" } }
      assert_redirected_to edit_password_path
    end
    change_password(current_password: temporary)
    assert_redirected_to settings_path
    assert_not member.reload.password_change_required?
    get root_path
    assert_response :success
    delete logout_path
    post login_path, params: { email: member.email, password: temporary }
    assert_response :unprocessable_entity
    post login_path, params: { email: member.email, password: NEW_PASSWORD }
    assert_redirected_to root_path
    delete logout_path
    member.update!(password_change_required: true)
    post login_path, params: { email: member.email, password: NEW_PASSWORD }
    assert_redirected_to edit_password_path
    delete logout_path
    assert_redirected_to login_path
  end

  test "existing accounts and new workspace managers are not forced to reset passwords" do
    %w[manager salesperson].each do |role|
      user = make_user(role: role)
      assert_not user.reload.password_change_required?
      login(user)
      get root_path
      assert_response :success
      delete logout_path
    end
    post signup_path, params: { workspace_name: "Compatible workspace", user: { name: "Manager", email: "compatible@example.test", password: NEW_PASSWORD, password_confirmation: NEW_PASSWORD, password_change_required: true } }
    assert_redirected_to root_path
    assert_not User.find_by!(email: "compatible@example.test").password_change_required?
  end

  test "CSRF is enforced and submitted secrets are filtered" do
    login(@user)
    old = PasswordsController.allow_forgery_protection
    PasswordsController.allow_forgery_protection = true
    assert_no_difference(["Session.count", "AuditEvent.count"]) { change_password }
    assert_response :unprocessable_entity
    assert @user.reload.authenticate("test-password-123")
    get edit_password_path
    token = Nokogiri::HTML(response.body).at_css("form[action='#{password_path}'] input[name=authenticity_token]")["value"]
    patch password_path, params: { authenticity_token: token, password_change: { current_password: "test-password-123", password: NEW_PASSWORD, password_confirmation: NEW_PASSWORD } }
    assert_redirected_to settings_path
    filtered = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(password_change: { current_password: "old-secret", password: "new-secret", password_confirmation: "new-secret" })
    assert_equal "[FILTERED]", filtered[:password_change]
    fields = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(current_password: "old-secret", password: "new-secret", password_confirmation: "new-secret")
    assert_equal ["[FILTERED]"] * 3, fields.values
  ensure
    PasswordsController.allow_forgery_protection = old
  end

  test "password attempts are rate limited per account and recover after ten minutes" do
    login(@user)
    digest = @user.password_digest
    5.times do
      change_password(current_password: "wrong-password")
      assert_response :unprocessable_entity
    end
    change_password
    assert_response :too_many_requests
    assert_equal digest, @user.reload.password_digest
    assert_select '[role=alert]', text: /Too many password-change attempts/
    colleague = make_user(organization: @user.organization, role: "salesperson")
    client = open_session
    client.post login_path, params: { email: colleague.email, password: "test-password-123" }
    change_password(client)
    client.assert_redirected_to settings_path
    travel_to 10.minutes.from_now + 1.second do
      change_password
      assert_redirected_to settings_path
    end
  end
end
