class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render "shared/error", locals: { message: "Too many login attempts. Try again in three minutes." }, status: :too_many_requests }
  def new
    redirect_to root_path if current_user
  end
  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.authenticate(params[:password])
      start_session(user)
      redirect_to root_path, notice: "Welcome back, #{user.name}.", status: :see_other
    else
      flash.now[:alert] = "Email or password is incorrect."
      render :new, status: :unprocessable_entity
    end
  end
  def destroy
    @login_session&.destroy!
    reset_session
    redirect_to login_path, notice: "You have signed out.", status: :see_other
  end
end
