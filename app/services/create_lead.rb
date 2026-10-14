class CreateLead
  def self.call(actor:, attributes:)
    owner = actor.organization.users.find(attributes[:owner_id].presence || actor.id)
    raise WorkflowError, "Only a manager can assign another owner" if owner != actor && !actor.manager?
    Lead.transaction do
      company = Company.create!(organization: actor.organization, name: attributes[:company_name], industry: attributes[:industry])
      contact = Contact.create!(organization: actor.organization, company: company, name: attributes[:contact_name], email: attributes[:contact_email], phone: attributes[:phone])
      lead = Lead.create!(organization: actor.organization, owner: owner, company: company, contact: contact, title: attributes[:title], notes: attributes[:notes])
      AuditEvent.record!(actor, lead, "created")
      lead
    end
  end
end
