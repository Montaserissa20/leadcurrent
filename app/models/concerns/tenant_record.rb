module TenantRecord
  extend ActiveSupport::Concern
  included do
    belongs_to :organization
    validate :check_tenant_associations
  end
  private
  def check_tenant_associations
    %i[owner actor company contact lead opportunity].each do |name|
      next unless self.class.reflect_on_association(name)
      record = public_send(name)
      errors.add(name, "must belong to this workspace") if record && record.organization_id != organization_id
    end
    if respond_to?(:contact) && contact && respond_to?(:company_id) && contact.company_id != company_id
      errors.add(:contact, "must belong to the selected company")
    end
  end
end
