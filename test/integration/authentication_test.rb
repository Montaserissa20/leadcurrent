require "test_helper"
class AuthenticationTest < ActionDispatch::IntegrationTest
  test "signup creates isolated organization and hashes password" do
    assert_difference(["User.count", "Organization.count"]) do
      post signup_path, params: { workspace_name: "New sales team", user: { name: "Morgan", email: "morgan@example.test", password: "secure-passphrase-123", password_confirmation: "secure-passphrase-123" } }
    end
    assert_redirected_to root_path
    user = User.find_by!(email: "morgan@example.test")
    assert user.manager?
    assert_not_equal "secure-passphrase-123", user.password_digest
    assert user.authenticate("secure-passphrase-123")
    get root_path
    assert_response :success
  end
  test "failed signup rolls back organization" do
    assert_no_difference(["Organization.count", "User.count"]) do
      post signup_path, params: { workspace_name: "Team", user: { name: "Bad", email: "bad", password: "short" } }
    end
    assert_response :unprocessable_entity
  end
  test "invalid login generic message logout invalidates database session" do
    user = make_user
    post login_path, params: { email: user.email, password: "wrong" }
    assert_response :unprocessable_entity
    assert_select '[role=alert]', text: /Email or password is incorrect/
    login(user)
    assert_difference("Session.count", -1) { delete logout_path }
    get root_path
    assert_redirected_to login_path
  end
  test "expired sessions cannot access protected pages" do
    user = make_user
    login(user)
    travel_to 13.hours.from_now do
      get leads_path
      assert_redirected_to login_path
    end
  end
  test "profile edits cannot escalate role and manager can add salesperson" do
    user = make_user
    login(user)
    patch settings_path, params: { user: { name: "New name", time_zone: "UTC", organization_id: 999, role: "salesperson" } }
    assert_equal "New name", user.reload.name
    assert_equal "manager", user.role
    assert_equal "UTC", user.time_zone
    post team_members_path, params: { user: { name: "Teammate", email: "member@example.test", password: "temporary-pass-123", role: "manager" } }
    member = User.find_by!(email: "member@example.test")
    assert_equal "salesperson", member.role
    assert_equal user.organization_id, member.organization_id
  end
  test "CSRF is enforced when forgery protection is enabled" do
    old = SessionsController.allow_forgery_protection
    SessionsController.allow_forgery_protection = true
    assert_no_difference("Session.count") do
      post login_path, params: { email: "nobody@example.test", password: "anything" }
    end
    assert_response :unprocessable_entity
  ensure
    SessionsController.allow_forgery_protection = old
  end
end
