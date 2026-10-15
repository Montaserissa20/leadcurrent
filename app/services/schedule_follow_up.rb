class ScheduleFollowUp
  def self.call(record, actor:, due_at:, title: nil)
    WorkspaceAccess.authorize!(actor, record)
    record.with_lock do
      WorkspaceAccess.authorize!(actor, record)
      raise WorkflowError, "Choose a future follow-up time" unless (due_at.is_a?(Time) || due_at.is_a?(ActiveSupport::TimeWithZone)) && due_at > Time.current
      raise WorkflowError, "Cannot schedule follow-up on a closed record" if (record.is_a?(Lead) && record.status.in?(%w[converted disqualified])) || (record.is_a?(Opportunity) && record.terminal?)
      task_title = title.nil? ? "Follow up: #{record.title}".truncate(200) : title
      existing = record.tasks.pending.find_by(due_at: due_at, title: task_title)
      return existing if existing
      task = Task.create!(organization: record.organization, owner: record.owner, record.class.name.underscore => record, title: task_title, due_at: due_at)
      AuditEvent.record!(actor, record, "follow_up_scheduled", task_id: task.id, due_at: due_at.iso8601)
      task
    end
  end
end
