require "test_helper"
class WorkflowTest < ActiveSupport::TestCase
  setup { @user = make_user; @lead = make_lead(@user) }
  test "lead validates title contact and tenant" do
    @lead.title = ""
    assert_not @lead.valid?
    @lead.title = "Valid title"
    @lead.owner = make_user
    assert_not @lead.valid?
    assert_includes @lead.errors[:owner], "must belong to this workspace"
  end
  test "status cannot bypass workflow through ordinary update" do
    assert_not @lead.update(status: "qualified")
    assert_equal "new", @lead.reload.status
    assert_not @lead.update(first_contact_at: Time.current)
    assert_nil @lead.reload.first_contact_at
    assert_not @lead.update(first_contact_deadline: 3.days.from_now)
  end
  test "contact requires completed activity before qualification" do
    assert_raises(WorkflowError) { LeadTransition.call(@lead, to: "contacted", actor: @user) }
    assert_raises(WorkflowError) { LeadTransition.call(@lead, to: "qualified", actor: @user) }
    qualify(@lead)
    assert_equal "qualified", @lead.reload.status
    assert_equal 2, AuditEvent.where(record_type: "Lead", record_id: @lead.id, action: "status_changed").count
  end
  test "all lead transition pairs match the explicit graph" do
    Lead::STATUSES.product(Lead::STATUSES).each do |from, to|
      lead = make_lead(@user)
      lead.update_columns(status: from, first_contact_at: Time.current)
      if LeadTransition::TRANSITIONS.fetch(from).include?(to)
        LeadTransition.call(lead, to: to, actor: @user)
        assert_equal to, lead.reload.status
      else
        assert_raises(WorkflowError, "#{from} -> #{to}") { LeadTransition.call(lead, to: to, actor: @user) }
        assert_equal from, lead.reload.status
      end
    end
  end
  test "conversion copies relationships and prevents duplicate conversion" do
    assert_raises(WorkflowError) { convert(@lead) }
    qualify(@lead)
    task = ScheduleFollowUp.call(@lead, actor: @user, due_at: 1.day.from_now)
    deal = convert(@lead)
    assert_equal "converted", @lead.reload.status
    assert_equal "qualification", deal.reload.status
    %i[organization_id owner_id company_id contact_id].each { |key| assert_equal @lead.public_send(key), deal.public_send(key) }
    assert_equal @lead.id, deal.lead_id
    assert_equal deal.id, task.reload.opportunity_id
    assert_nil task.lead_id
    assert_raises(WorkflowError) { convert(Lead.find(@lead.id)) }
    assert_equal 1, Opportunity.where(lead_id: @lead.id).count
  end
  test "invalid conversion rolls back lead and opportunity" do
    qualify(@lead)
    assert_no_difference(["Opportunity.count", "AuditEvent.count"]) do
      assert_raises(ActiveRecord::RecordInvalid) { convert(@lead, value: -1) }
    end
    assert_equal "qualified", @lead.reload.status
  end
  test "all opportunity transition pairs match graph including terminal states" do
    Opportunity::STATUSES.product(Opportunity::STATUSES).each do |from, to|
      deal = make_opportunity(@user)
      deal.update_columns(status: from, closed_at: from.in?(%w[won lost]) ? Time.current : nil)
      if OpportunityTransition::TRANSITIONS.fetch(from).include?(to)
        OpportunityTransition.call(deal, to: to, actor: @user)
        assert_equal to, deal.reload.status
        assert_equal to.in?(%w[won lost]), deal.closed_at.present?
      else
        assert_raises(WorkflowError, "#{from} -> #{to}") { OpportunityTransition.call(deal, to: to, actor: @user) }
        assert_equal from, deal.reload.status
      end
    end
  end
  test "unauthorized owners and tenants cannot execute workflow actions" do
    colleague = make_user(organization: @user.organization, role: "salesperson")
    stranger = make_user
    [colleague, stranger].each do |actor|
      error = actor == stranger ? ActiveRecord::RecordNotFound : WorkflowError
      assert_raises(error) { RecordActivity.call(@lead, actor: actor, kind: "contact", body: "Bad") }
      assert_raises(error) { LeadTransition.call(@lead, to: "disqualified", actor: actor) }
      assert_raises(error) { convert(@lead, actor: actor) }
      assert_raises(error) { ScheduleFollowUp.call(@lead, actor: actor, due_at: 1.day.from_now) }
    end
    deal = make_opportunity(@user)
    assert_raises(WorkflowError) { OpportunityTransition.call(deal, to: "proposal", actor: colleague) }
    assert_raises(ActiveRecord::RecordNotFound) { OpportunityTransition.call(deal, to: "proposal", actor: stranger) }
  end
  test "opportunity direct status change and inconsistent contact are rejected" do
    deal = make_opportunity(@user)
    assert_not deal.update(status: "won", closed_at: Time.current)
    deal.reload
    other = make_lead(@user)
    deal.contact = other.contact
    assert_not deal.valid?
  end
  test "contact and follow-up are atomic when scheduling fails" do
    assert_no_difference(["Activity.count", "Task.count", "AuditEvent.count"]) do
      assert_raises(WorkflowError) { RecordActivity.call(@lead, actor: @user, kind: "contact", body: "Call", follow_up_at: 1.hour.ago) }
    end
    assert_equal "new", @lead.reload.status
    assert_nil @lead.first_contact_at
  end
end
