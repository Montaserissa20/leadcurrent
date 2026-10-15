class CustomerProfile
  attr_reader :leads, :opportunities, :activities, :tasks

  def initialize(user, record)
    raise ActiveRecord::RecordNotFound unless record.organization_id == user.organization_id
    @leads = WorkspaceAccess.scope(user, Lead).where(contact_id: record.contact_id, company_id: record.company_id)
    @opportunities = WorkspaceAccess.scope(user, Opportunity).where(contact_id: record.contact_id, company_id: record.company_id)
    @activities = related(WorkspaceAccess.scope(user, Activity)).includes(:actor, :lead, :opportunity).order(completed_at: :desc, id: :desc).limit(50)
    @tasks = related(WorkspaceAccess.scope(user, Task)).includes(:owner, :lead, :opportunity).order(completed_at: :desc, due_at: :asc).limit(50)
  end

  private
  def related(relation)
    relation.where(lead_id: leads.select(:id)).or(relation.where(opportunity_id: opportunities.select(:id)))
  end
end
