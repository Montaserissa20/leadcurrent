class TasksController < ApplicationController
  def index
    @tasks = scope(Task).includes(:lead, :opportunity, :owner).order(completed_at: :desc, due_at: :asc).limit(100)
    @tasks = @tasks.pending if params[:status] == "pending"
  end
  def complete
    task = scope(Task).find(params[:id])
    WorkspaceAccess.authorize!(current_user, task)
    task.with_lock do
      WorkspaceAccess.authorize!(current_user, task)
      raise WorkflowError, "This task is already complete" if task.completed_at
      task.update!(completed_at: Time.current)
      AuditEvent.record!(current_user, task, "completed")
    end
    redirect_to tasks_path, notice: "Follow-up task completed. Record actual customer contact on the lead or opportunity separately.", status: :see_other
  end
end
