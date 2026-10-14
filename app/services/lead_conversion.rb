class LeadConversion
  def self.call(lead, actor:, attributes:)
    WorkspaceAccess.authorize!(actor, lead)
    lead.with_lock do
      WorkspaceAccess.authorize!(actor, lead)
      raise WorkflowError, "Only a qualified lead can be converted once" unless lead.status == "qualified" && !lead.opportunity
      opportunity = Opportunity.new(attributes.slice(:title, :value, :currency, :expected_closing_date))
      opportunity.assign_attributes(organization: lead.organization, owner: lead.owner, company: lead.company, contact: lead.contact, lead: lead, last_activity_at: Time.current)
      opportunity.workflow_change = true
      opportunity.save!
      opportunity.workflow_change = false
      lead.workflow_change = true
      lead.update!(status: "converted")
      lead.tasks.pending.each do |task|
        task.update!(lead: nil, opportunity: opportunity)
      end
      AuditEvent.record!(actor, lead, "converted", opportunity_id: opportunity.id)
      AuditEvent.record!(actor, opportunity, "created_from_lead", lead_id: lead.id)
      opportunity
    ensure
      lead.workflow_change = false
    end
  end
end
