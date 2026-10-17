class SettingsController < ApplicationController
  def show
    response.headers["Cache-Control"] = "no-store"
  end
  def update
    current_user.update!(params.require(:user).permit(:name, :time_zone))
    redirect_to settings_path, notice: "Profile updated.", status: :see_other
  end
  def create_member
    raise WorkflowError, "Only workspace managers can add team members" unless current_user.manager?
    user = current_user.organization.users.create!(params.require(:user).permit(:name, :email, :password, :password_confirmation).merge(role: "salesperson", password_change_required: true))
    AuditEvent.record!(current_user, user, "team_member_created")
    redirect_to settings_path, notice: "Team member added. Share their temporary password securely.", status: :see_other
  end
end
