class TasksController < ApplicationController
  def index
    records = scope(Task)
    if params[:contact_id].present?
      contact = scope(Contact).find(params[:contact_id])
      records = records.where(lead_id: scope(Lead).where(contact_id: contact.id).select(:id))
        .or(records.where(opportunity_id: scope(Opportunity).where(contact_id: contact.id).select(:id)))
    end
    records = records.where(lead_id: scope(Lead).find(params[:lead_id]).id) if params[:lead_id].present?
    records = records.where(opportunity_id: scope(Opportunity).find(params[:opportunity_id]).id) if params[:opportunity_id].present?
    records = case params[:status]
    when "pending" then records.pending
    when "overdue" then records.overdue
    when "today" then records.pending.where(due_at: Time.current.beginning_of_day..Time.current.end_of_day)
    when "completed" then records.where.not(completed_at: nil)
    else records
    end
    records = records.where("title ILIKE ?", "%#{Task.sanitize_sql_like(params[:q].to_s)}%") if params[:q].present?
    @tasks = records.includes(:lead, :opportunity, :owner).order(Arel.sql("completed_at ASC NULLS FIRST"), :due_at, :id).limit(100)
  end
  def create
    model = { "Lead" => Lead, "Opportunity" => Opportunity }[params[:record_type]]
    raise WorkflowError, "Choose a lead or opportunity" unless model
    record = scope(model).find(params[:record_id])
    ScheduleFollowUp.call(record, actor: current_user, title: params.require(:task)[:title], due_at: parse_time(params[:task][:due_at]))
    redirect_to record, notice: "Task created.", status: :see_other
  end
  def edit
    @task = scope(Task).find(params[:id])
    WorkspaceAccess.authorize!(current_user, @task)
    WorkspaceAccess.authorize!(current_user, @task.record)
  end
  def update
    task = scope(Task).find(params[:id])
    data = params.require(:task).permit(:title, :due_at)
    ManageTask.update(task, actor: current_user, title: data[:title], due_at: parse_time(data[:due_at]))
    redirect_to task.record, notice: "Task updated.", status: :see_other
  end
  def complete
    task = scope(Task).find(params[:id])
    ManageTask.complete(task, actor: current_user)
    destination = params[:from_dashboard] == "true" ? root_path : params[:from_profile] == "true" ? polymorphic_path(task.record) : tasks_path
    redirect_to destination, notice: "Follow-up task completed. Record actual customer contact on the lead or opportunity separately.", status: :see_other
  end
end
