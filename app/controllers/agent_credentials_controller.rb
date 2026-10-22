class AgentCredentialsController < ApplicationController
  before_action :require_manager
  before_action :private_response
  def index
    @credentials = scope(AgentCredential).order(created_at: :desc).limit(100)
  end
  def create
    input = params.require(:agent_credential).permit(:name, :expires_at)
    expires_at = input[:expires_at].present? ? Time.zone.iso8601(input[:expires_at]) : nil
    @credential, @issued_token = AgentCredential.issue!(actor: current_user, name: input[:name], expires_at: expires_at)
    render :created, status: :created
  rescue ArgumentError, TypeError
    raise WorkflowError, "Choose a valid future expiry or leave it empty"
  end
  def revoke
    scope(AgentCredential).find(params[:id]).revoke!(actor: current_user)
    redirect_to agent_credentials_path, notice: "Agent credential revoked.", status: :see_other
  end
  private
  def require_manager
    render "shared/error", locals: { message: "Only workspace managers can manage agent credentials." }, status: :forbidden unless current_user.manager?
  end
  def private_response
    response.headers["Cache-Control"] = "no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Referrer-Policy"] = "no-referrer"
  end
end
