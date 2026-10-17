class PasswordsController < ApplicationController
  skip_before_action :require_password_change
  before_action :prevent_password_caching
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  rate_limit to: 5, within: 10.minutes, by: -> { current_user.id }, store: RATE_LIMIT_STORE, only: :update,
    with: -> { render_password_errors(["Too many password-change attempts. Try again in ten minutes."], status: :too_many_requests) }

  def edit
  end

  def update
    submitted = params.require(:password_change)
    raise ActionController::BadRequest, "Invalid password-change form" unless submitted.is_a?(ActionController::Parameters)
    allowed = %w[current_password password password_confirmation]
    if (submitted.keys - allowed).any? || params.key?(:user_id) || params.key?(:id) || params.key?(:user)
      return render_password_errors(["Only your own password can be changed."])
    end
    values = submitted.permit(*allowed).to_h.symbolize_keys.transform_values(&:to_s)
    replacement = ChangePassword.call(current_user, current_session: @login_session,
      current_password: values[:current_password].to_s, password: values[:password].to_s,
      password_confirmation: values[:password_confirmation].to_s)
    reset_session
    session[:login_session_id] = replacement.id
    redirect_to settings_path, notice: "Password changed. Your other sessions have been signed out.", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    errors = error.record.errors.full_messages
    # A failed update leaves assigned attributes in memory; retain the DB-enforced onboarding state.
    current_user.reload
    render_password_errors(errors)
  rescue ChangePassword::SessionExpired
    reset_session
    redirect_to login_path, alert: "Your session expired. Sign in again.", status: :see_other
  end

  private
  def prevent_password_caching
    response.headers["Cache-Control"] = "no-store"
  end

  def render_password_errors(errors, status: :unprocessable_entity)
    @password_errors = errors
    render :edit, status: status
  end
end
