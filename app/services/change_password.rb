class ChangePassword
  class SessionExpired < StandardError; end

  def self.call(user, current_session:, current_password:, password:, password_confirmation:)
    user.with_lock do
      # Login also locks this user: an old password cannot create a session after revocation.
      active_session = Session.where(user: user, id: current_session.id).where("expires_at > ?", Time.current).first
      raise SessionExpired unless active_session

      user.errors.clear
      unless current_password.present? && current_password.bytesize <= 72 && user.authenticate(current_password)
        user.errors.add(:current_password, "is incorrect")
        raise ActiveRecord::RecordInvalid, user
      end
      user.errors.add(:password, "can't be blank") if password.blank?
      user.errors.add(:password_confirmation, "can't be blank") if password_confirmation.blank?
      user.errors.add(:password, "must be different from your current password") if password.present? && user.authenticate(password)
      raise ActiveRecord::RecordInvalid, user if user.errors.any?

      user.update!(password: password, password_confirmation: password_confirmation, password_change_required: false)
      sessions = Session.where(user: user)
      revoked = sessions.where.not(id: active_session.id).count
      sessions.delete_all
      replacement = Session.create!(user: user, expires_at: active_session.expires_at)
      AuditEvent.record!(user, user, "password_changed", other_sessions_revoked: revoked)
      replacement
    end
  end
end
