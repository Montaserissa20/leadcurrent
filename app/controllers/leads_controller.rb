class LeadsController < ApplicationController
  def index
    records = filter_records(scope(Lead))
    records = records.overdue.where.not(status: %w[converted disqualified]) if params[:attention] == "overdue"
    ordering = params[:attention] == "overdue" ? { first_contact_deadline: :asc, id: :asc } : { updated_at: :desc }
    @leads = records.includes(:company, :contact, :owner).order(ordering).limit(100)
  end
  def show
    @lead = scope(Lead).find(params[:id])
    @source_inquiry = scope(AgentInquiry).find_by(accepted_lead_id: @lead.id)
    @profile = CustomerProfile.new(current_user, @lead)
    @recommendation = NextBestAction.new(current_user).call(record: @lead, limit: 1).first
  end
  def new
    @lead = Lead.new
  end
  def create
    @lead = CreateLead.call(actor: current_user, attributes: lead_params.to_h.symbolize_keys)
    redirect_to @lead, notice: "Lead created. First contact is due within 24 hours.", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    @lead = Lead.new(title: lead_params[:title], notes: lead_params[:notes])
    @form_error = error.message
    render :new, status: :unprocessable_entity
  end
  def edit
    @lead = scope(Lead).find(params[:id])
    WorkspaceAccess.authorize!(current_user, @lead)
  end
  def update
    @lead = scope(Lead).find(params[:id])
    WorkspaceAccess.authorize!(current_user, @lead)
    data = lead_params.slice(:title, :notes, :owner_id)
    if data[:owner_id].present? && data[:owner_id].to_i != @lead.owner_id
      raise WorkflowError, "Only a manager can reassign leads" unless current_user.manager?
      data[:owner_id] = current_user.organization.users.find(data[:owner_id]).id
    end
    @lead.with_lock do
      WorkspaceAccess.authorize!(current_user, @lead)
      @lead.update!(data)
      AuditEvent.record!(current_user, @lead, "updated", fields: data.keys)
    end
    redirect_to @lead, notice: "Lead updated.", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    @form_error = error.message
    render :edit, status: :unprocessable_entity
  end
  def transition
    lead = scope(Lead).find(params[:id])
    LeadTransition.call(lead, to: params[:status], actor: current_user)
    redirect_to lead, notice: "Lead moved to #{lead.status.humanize}.", status: :see_other
  end
  def convert
    lead = scope(Lead).find(params[:id])
    opportunity = LeadConversion.call(lead, actor: current_user, attributes: params.require(:opportunity).permit(:title, :value, :currency, :expected_closing_date).to_h.symbolize_keys)
    redirect_to opportunity, notice: "Lead converted to an opportunity.", status: :see_other
  end
  private
  def lead_params
    params.require(:lead).permit(:title, :notes, :owner_id, :company_name, :industry, :contact_name, :contact_email, :phone)
  end
end
