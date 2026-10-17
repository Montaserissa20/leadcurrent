require "test_helper"

class ChangePasswordTest < ActiveSupport::TestCase
  setup do
    @user = make_user(role: "salesperson")
    @user.update!(password_change_required: true)
    @session = Session.create!(user: @user, expires_at: 12.hours.from_now)
    @replacement = SecureRandom.base64(24)
  end

  def replace_password
    ChangePassword.call(@user, current_session: @session, current_password: "test-password-123",
      password: @replacement, password_confirmation: @replacement)
  end

  test "expired or revoked authentication cannot create a replacement session" do
    @session.update!(expires_at: 1.second.ago)
    assert_raises(ChangePassword::SessionExpired) { replace_password }
    assert @user.reload.authenticate("test-password-123")
    @session.destroy!
    assert_raises(ChangePassword::SessionExpired) { replace_password }
    assert @user.reload.password_change_required?
    assert_empty Session.where(user: @user)
  end

  test "invalid confirmation preserves the temporary requirement and every active session" do
    other = Session.create!(user: @user, expires_at: 12.hours.from_now)
    old_ids = Session.where(user: @user).order(:id).pluck(:id)
    assert_raises(ActiveRecord::RecordInvalid) do
      ChangePassword.call(@user, current_session: @session, current_password: "test-password-123",
        password: @replacement, password_confirmation: "mismatch")
    end
    assert @user.reload.authenticate("test-password-123")
    assert @user.password_change_required?
    assert_equal old_ids, Session.where(user: @user).order(:id).pluck(:id)
    assert Session.exists?(other.id)
    assert_empty AuditEvent.where(action: "password_changed")
  end
end
