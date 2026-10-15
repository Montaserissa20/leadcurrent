class ManageTask
  def self.update(task, actor:, title:, due_at:)
    mutate(task, actor: actor) do
      raise WorkflowError, "Completed tasks cannot be edited" if task.completed_at
      record = task.record
      raise WorkflowError, "Cannot reschedule a closed record" if record.is_a?(Lead) ? record.status.in?(%w[converted disqualified]) : record.terminal?
      raise WorkflowError, "Choose a future follow-up time" unless due_at && due_at > Time.current
      task.update!(title: title, due_at: due_at)
      AuditEvent.record!(actor, task, "updated", fields: %w[title due_at])
    end
  end

  def self.complete(task, actor:)
    mutate(task, actor: actor) do
      raise WorkflowError, "This task is already complete" if task.completed_at
      task.update!(completed_at: Time.current)
      AuditEvent.record!(actor, task, "completed")
    end
  end

  def self.mutate(task, actor:)
    # Match conversion's parent-before-task lock order and recheck current ownership.
    parent = task.record
    parent.with_lock do
      task.with_lock do
        raise WorkflowError, "Task moved to another record; reload and try again" unless task.record == parent
        WorkspaceAccess.authorize!(actor, task)
        WorkspaceAccess.authorize!(actor, task.record)
        yield
      end
    end
    task
  end
  private_class_method :mutate
end
