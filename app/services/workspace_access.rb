class WorkspaceAccess
  def self.scope(user, model) = model.where(organization_id: user.organization_id)
  def self.authorize!(user, record)
    raise ActiveRecord::RecordNotFound unless record.organization_id == user.organization_id
    owner_id = record.respond_to?(:owner_id) ? record.owner_id : nil
    raise WorkflowError, "Only the owner or workspace manager can change this record" if owner_id && owner_id != user.id && !user.manager?
  end
end
