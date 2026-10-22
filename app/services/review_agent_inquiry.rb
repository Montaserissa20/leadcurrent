class ReviewAgentInquiry
  def self.call(inquiry:, actor:, decision:, owner_id: nil, reason: nil)
    raise WorkflowError, "Only workspace managers can review agent inquiries" unless actor.manager?
    WorkspaceAccess.authorize!(actor, inquiry)
    raise WorkflowError, "Choose a valid review decision" unless decision.in?(%w[accept reject request_information])
    raise WorkflowError, "Keep the review reason within 500 characters" unless reason.nil? || reason.is_a?(String) && reason.length <= 500
    if owner_id.present? && !(owner_id.is_a?(Integer) && owner_id.positive? || owner_id.is_a?(String) && owner_id.match?(/\A[1-9]\d{0,18}\z/))
      raise WorkflowError, "Choose a valid owner from this workspace"
    end
    raise WorkflowError, "Do not include credentials in review reasons" if reason.is_a?(String) && reason.match?(AgentIntake::Payload::CREDENTIAL)
    inquiry.with_lock do
      WorkspaceAccess.authorize!(actor, inquiry)
      raise WorkflowError, "This inquiry has already received a final decision" unless inquiry.reviewable?
      if decision == "accept"
        raise WorkflowError, "Contact name and email are required before acceptance; request more information instead" if inquiry.missing_lead_fields.any?
        owner = WorkspaceAccess.scope(actor, User).find(owner_id.presence || actor.id)
        lead = CreateLead.call(actor: actor, attributes: { owner_id: owner.id, company_name: inquiry.company_name, contact_name: inquiry.contact_name, contact_email: inquiry.contact_email,
          title: inquiry.product_or_service, notes: provenance_notes(inquiry) })
        status = "accepted"
      elsif decision == "reject"
        status = "rejected"
      else
        raise WorkflowError, "Information has already been requested" if inquiry.status == "needs_information"
        status = "needs_information"
      end
      inquiry.review_change = true
      inquiry.update!(status: status, reviewed_by: actor, reviewed_at: Time.current, accepted_lead: lead, review_reason: reason.presence)
      AuditEvent.record!(actor, inquiry, "agent_inquiry_#{status}", lead_id: lead&.id)
      AuditEvent.record!(actor, lead, "created_from_agent_inquiry", inquiry_id: inquiry.id) if lead
      inquiry
    ensure
      inquiry.review_change = false
    end
  end

  def self.provenance_notes(inquiry)
    ["Source: External AI Agent inquiry ##{inquiry.id}. Identity, authority and stated budget remain UNVERIFIED. Human acceptance creates a CRM lead, not a purchase or completed customer contact.",
      "Claimed quantity: #{inquiry.quantity || 'not supplied'}. Stated budget: #{inquiry.stated_budget || 'not supplied'} #{inquiry.currency}.",
      "Claimed timeline: #{inquiry.desired_timeline || 'not supplied'}.", inquiry.requirements, inquiry.message].compact.join("\n\n")
  end
  private_class_method :provenance_notes
end
