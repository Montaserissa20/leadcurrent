class RegistrationsController < ApplicationController
  skip_before_action :require_login
  rate_limit to: 5, within: 10.minutes, only: :create
  def new
    @user = User.new
  end
  def create
    @user = User.new(params.require(:user).permit(:name, :email, :password, :password_confirmation))
    User.transaction do
      @user.organization = Organization.create!(name: params[:workspace_name])
      @user.role = "manager"
      @user.save!
    end
    start_session(@user)
    redirect_to root_path, notice: "Your workspace is ready. Create your first lead.", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    @form_error = error.message
    render :new, status: :unprocessable_entity
  end
end
