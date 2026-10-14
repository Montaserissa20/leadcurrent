class LeadTransition
  TRANSITIONS = {
    "new" => %w[contacted disqualified], "contacted" => %w[qualified disqualified],
    "qualified" => %w[disqualified], "converted" => [], "disqualified" => []
  }.freeze
  def self.call(lead, to:, actor:)
    WorkspaceAccess.authorize!(actor, lead)
    lead.with_lock do
      raise WorkflowError, "Cannot move #{lead.status} to #{to}" unless TRANSITIONS.fetch(lead.status).include?(to)
      raise WorkflowError, "Record a completed customer contact first" if to == "contacted" && lead.first_contact_at.nil?
      from = lead.status
      lead.workflow_change = true
      lead.update!(status: to)
      AuditEvent.record!(actor, lead, "status_changed", from: from, to: to)
    ensure
      lead.workflow_change = false
    end
    lead
  end
end
