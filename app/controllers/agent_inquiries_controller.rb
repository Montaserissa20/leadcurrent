class AgentInquiriesController < ApplicationController
  before_action :private_response
  before_action :load_inquiry, only: %i[show review analyze]
  before_action :require_manager, only: %i[review analyze]
  def index
    @counts = scope(AgentInquiry).group(:status).count
    @status = params[:status].to_s
    raise WorkflowError, "Choose a valid inquiry status" if @status.present? && !AgentInquiry::STATUSES.include?(@status)
    @inquiries = scope(AgentInquiry).includes(:agent_credential).order(submitted_at: :desc, id: :desc)
    @inquiries = @inquiries.where(status: @status) if @status.present?
    @inquiries = @inquiries.limit(100)
  end
  def show
    @owners = scope(User).order(:name)
  end
  def review
    ReviewAgentInquiry.call(inquiry: @inquiry, actor: current_user, decision: params[:decision], owner_id: params[:owner_id], reason: params[:reason])
    if @inquiry.status == "accepted"
      redirect_to lead_path(@inquiry.accepted_lead_id), notice: "Inquiry accepted. A new lead was created; identity and purchasing claims remain unverified.", status: :see_other
    else
      redirect_to @inquiry, notice: "Human review recorded. No customer message was sent.", status: :see_other
    end
  end
  def analyze
    @owners = scope(User).order(:name)
    @analysis = Ai::RequestGate.call(current_user) { AgentIntake::Qualifier.new.call(@inquiry, actor: current_user) }
    render :show
  rescue Ai::Error => error
    @ai_error = error.message
    render :show, status: error.code == :rate_limited ? :too_many_requests : :service_unavailable
  end
  private
  def load_inquiry = @inquiry = scope(AgentInquiry).find(params[:id])
  def private_response = response.headers["Cache-Control"] = "no-store"
  def require_manager
    render "shared/error", locals: { message: "Only workspace managers can review or analyze agent inquiries." }, status: :forbidden unless current_user.manager?
  end
end
