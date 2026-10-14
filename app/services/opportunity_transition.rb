class OpportunityTransition
  TRANSITIONS = {
    "qualification" => %w[proposal lost], "proposal" => %w[negotiation lost],
    "negotiation" => %w[won lost], "won" => [], "lost" => []
  }.freeze
  def self.call(opportunity, to:, actor:)
    WorkspaceAccess.authorize!(actor, opportunity)
    opportunity.with_lock do
      raise WorkflowError, "Cannot move #{opportunity.status} to #{to}" unless TRANSITIONS.fetch(opportunity.status).include?(to)
      from = opportunity.status
      opportunity.workflow_change = true
      opportunity.update!(status: to, closed_at: to.in?(%w[won lost]) ? Time.current : nil, last_activity_at: Time.current)
      AuditEvent.record!(actor, opportunity, "status_changed", from: from, to: to)
    ensure
      opportunity.workflow_change = false
    end
    opportunity
  end
end
