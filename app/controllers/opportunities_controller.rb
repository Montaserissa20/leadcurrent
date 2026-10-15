class OpportunitiesController < ApplicationController
  def index
    @opportunities = filtered
  end
  def pipeline
    @by_stage = filtered.group_by(&:status)
  end
  def show
    @opportunity = scope(Opportunity).find(params[:id])
    @profile = CustomerProfile.new(current_user, @opportunity)
    @recommendation = NextBestAction.new(current_user).call(record: @opportunity, limit: 1).first
  end
  def edit
    @opportunity = scope(Opportunity).find(params[:id])
    WorkspaceAccess.authorize!(current_user, @opportunity)
  end
  def update
    @opportunity = scope(Opportunity).find(params[:id])
    WorkspaceAccess.authorize!(current_user, @opportunity)
    data = params.require(:opportunity).permit(:title, :value, :currency, :expected_closing_date, :owner_id)
    if data[:owner_id].present? && data[:owner_id].to_i != @opportunity.owner_id
      raise WorkflowError, "Only a manager can reassign opportunities" unless current_user.manager?
      data[:owner_id] = current_user.organization.users.find(data[:owner_id]).id
    end
    @opportunity.with_lock do
      WorkspaceAccess.authorize!(current_user, @opportunity)
      @opportunity.update!(data)
      AuditEvent.record!(current_user, @opportunity, "updated", fields: data.keys)
    end
    redirect_to @opportunity, notice: "Opportunity updated.", status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    @form_error = error.message
    render :edit, status: :unprocessable_entity
  end
  def transition
    opportunity = scope(Opportunity).find(params[:id])
    OpportunityTransition.call(opportunity, to: params[:status], actor: current_user)
    destination = params[:from_dashboard] == "true" ? root_path : params[:from_pipeline] == "true" ? pipeline_path : opportunity_path(opportunity)
    redirect_to destination, notice: "Opportunity moved to #{opportunity.status.humanize}.", status: :see_other
  end
  private
  def filtered
    records = filter_records(scope(Opportunity))
    records = records.unscope(where: :status).active if params[:status] == "active"
    records.includes(:company, :contact, :owner).order(expected_closing_date: :asc).limit(100)
  end
end
