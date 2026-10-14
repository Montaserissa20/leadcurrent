class RecordActivity
  def self.call(record, actor:, kind:, body:, follow_up_at: nil)
    WorkspaceAccess.authorize!(actor, record)
    record.with_lock do
      WorkspaceAccess.authorize!(actor, record)
      raise WorkflowError, "This lead is closed; use the connected opportunity" if record.is_a?(Lead) && record.status.in?(%w[converted disqualified])
      raise WorkflowError, "This opportunity is closed" if record.is_a?(Opportunity) && record.terminal?
      activity = Activity.create!(organization: record.organization, actor: actor, record.class.name.underscore => record, kind: kind, body: body, completed_at: Time.current)
      if record.is_a?(Lead) && kind == "contact" && record.first_contact_at.nil?
        record.workflow_change = true
        record.update!(first_contact_at: activity.completed_at)
        LeadTransition.call(record, to: "contacted", actor: actor) if record.status == "new"
      elsif record.is_a?(Opportunity)
        record.update!(last_activity_at: activity.completed_at)
      end
      ScheduleFollowUp.call(record, actor: actor, due_at: follow_up_at) if follow_up_at.present?
      AuditEvent.record!(actor, record, "activity_recorded", activity_id: activity.id, kind: kind)
      activity
    ensure
      record.workflow_change = false if record.respond_to?(:workflow_change=)
    end
  end
end
