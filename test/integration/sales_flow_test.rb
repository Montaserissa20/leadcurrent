require "test_helper"
class SalesFlowTest < ActionDispatch::IntegrationTest
  setup { @user = make_user }
  test "signed in user completes persistent lead to won deal flow and dashboard totals" do
    get root_path
    assert_redirected_to login_path
    login(@user)
    get root_path
    assert_response :success
    post leads_path, params: { lead: { title: "Atlas platform", company_name: "Atlas Industries", contact_name: "Sam", contact_email: "sam@example.test" } }
    lead = @user.organization.leads.last
    assert_redirected_to lead_path(lead)
    patch lead_path(lead), params: { lead: { title: "Atlas annual platform", status: "converted" } }
    assert_equal "new", lead.reload.status
    assert_equal "Atlas annual platform", lead.title
    post actions_path, params: { record_type: "Lead", record_id: lead.id, action_kind: "contact", body: "Completed discovery call", follow_up_at: 1.day.from_now.iso8601, from_dashboard: "true" }
    assert_redirected_to root_path
    assert_equal "contacted", lead.reload.status
    assert_equal 1, lead.activities.count
    assert_equal 1, lead.tasks.pending.count
    post transition_lead_path(lead), params: { status: "qualified" }
    assert_equal "qualified", lead.reload.status
    post convert_lead_path(lead), params: { opportunity: { title: "Atlas annual platform", value: 18000, currency: "USD", expected_closing_date: 30.days.from_now.to_date } }
    deal = lead.reload.opportunity
    assert_redirected_to opportunity_path(deal)
    %w[proposal negotiation won].each do |status|
      post transition_opportunity_path(deal), params: { status: status }
      assert_redirected_to opportunity_path(deal)
      assert_equal status, deal.reload.status
    end
    get root_path
    assert_select '[data-stat="won_opportunities"]', text: /1 deals won/
    assert_select '[data-stat="won_value"]', text: /18,000/
    assert_select '[data-stat="active_opportunities"] strong', text: "0"
    get pipeline_path
    assert_select "[data-stage=won] [data-deal-id='#{deal.id}']"
    assert AuditEvent.where(record_type: "Opportunity", record_id: deal.id, action: "status_changed").count == 3
  end
  test "dashboard direct action persists contact and followup with one form submission" do
    lead = make_lead(@user, created_at: 25.hours.ago)
    login(@user)
    get root_path
    assert_select "form[action='#{actions_path}']", count: 1
    assert_difference(["Activity.count", "Task.count"], 1) do
      post actions_path, params: { record_type: "Lead", record_id: lead.id, action_kind: "contact", body: "Contact made", follow_up_at: 1.day.from_now.iso8601, from_dashboard: "true" }
    end
    follow_redirect!
    assert_response :success
    assert_select '[data-stat="overdue_contacts"] strong', text: "0"
    assert_select '[data-recommendation-id]', count: 0
    assert_equal "Contact made", lead.activities.last.body
  end
  test "foreign tenant records cannot be read edited converted or acted upon" do
    foreign = make_lead(make_user)
    login(@user)
    get lead_path(foreign)
    assert_response :not_found
    patch lead_path(foreign), params: { lead: { title: "Stolen" } }
    assert_response :not_found
    post transition_lead_path(foreign), params: { status: "disqualified" }
    assert_response :not_found
    post convert_lead_path(foreign), params: { opportunity: { title: "Bad" } }
    assert_response :not_found
    post actions_path, params: { record_type: "Lead", record_id: foreign.id, action_kind: "contact", body: "Bad" }
    assert_response :not_found
    get leads_path
    assert_select "a[href='#{lead_path(foreign)}']", count: 0
    assert_equal "new", foreign.reload.status
  end
  test "salesperson cannot edit colleague or assign self another tenant owner" do
    colleague = make_user(organization: @user.organization, role: "salesperson")
    lead = make_lead(@user)
    login(colleague)
    patch lead_path(lead), params: { lead: { title: "Not allowed" } }
    assert_response :unprocessable_entity
    assert_equal "Enterprise agreement", lead.reload.title
    post leads_path, params: { lead: { title: "Bad assignment", company_name: "Company", contact_name: "Sam", contact_email: "sam@example.test", owner_id: @user.id } }
    assert_response :unprocessable_entity
  end
  test "manager can assign team member and cannot assign foreign workspace" do
    teammate = make_user(organization: @user.organization, role: "salesperson")
    lead = make_lead(@user)
    login(@user)
    patch lead_path(lead), params: { lead: { owner_id: teammate.id } }
    assert_equal teammate.id, lead.reload.owner_id
    foreign = make_user
    patch lead_path(lead), params: { lead: { owner_id: foreign.id } }
    assert_response :not_found
    assert_equal teammate.id, lead.reload.owner_id
  end
  test "invalid forms return errors without orphan company or contact" do
    login(@user)
    assert_no_difference(["Lead.count", "Contact.count", "Company.count"]) do
      post leads_path, params: { lead: { title: "", company_name: "Bad", contact_name: "Sam", contact_email: "sam@example.test" } }
    end
    assert_response :unprocessable_entity
    assert_select '[role=alert]', text: /Title/
  end
  test "opportunity edit authorization stage bypass and invalid stage requests" do
    deal = make_opportunity(@user)
    login(@user)
    patch opportunity_path(deal), params: { opportunity: { value: 24000, status: "won", closed_at: Time.current } }
    assert_equal 24000, deal.reload.value
    assert_equal "qualification", deal.status
    post transition_opportunity_path(deal), params: { status: "won" }
    assert_response :unprocessable_entity
    stranger = make_opportunity(make_user)
    get opportunity_path(stranger)
    assert_response :not_found
    post transition_opportunity_path(stranger), params: { status: "proposal" }
    assert_response :not_found
    patch opportunity_path(stranger), params: { opportunity: { value: 1 } }
    assert_response :not_found
  end
  test "task completion is persistent authorized and does not satisfy first contact" do
    lead = make_lead(@user)
    task = ScheduleFollowUp.call(lead, actor: @user, due_at: 1.day.from_now)
    foreign = ScheduleFollowUp.call(make_lead(make_user), actor: User.last, due_at: 1.day.from_now)
    login(@user)
    post complete_task_path(foreign)
    assert_response :not_found
    post complete_task_path(task)
    assert task.reload.completed_at
    assert_nil lead.reload.first_contact_at
    post complete_task_path(task)
    assert_response :unprocessable_entity
  end
  test "search owner and stage filters are database backed" do
    lead = make_lead(@user)
    login(@user)
    get leads_path, params: { q: "Enterprise", owner_id: @user.id, status: "new" }
    assert_select "a[href='#{lead_path(lead)}']"
    get leads_path, params: { q: "Unmatched" }
    assert_select "a[href='#{lead_path(lead)}']", count: 0
  end
  test "all required pages render and currencies stay separate" do
    usd = make_opportunity(@user)
    eur = convert(qualify(make_lead(@user)), currency: "EUR", value: 3000)
    login(@user)
    [root_path, leads_path, lead_path(usd.lead), new_lead_path, edit_lead_path(usd.lead), opportunities_path, opportunity_path(eur), edit_opportunity_path(eur), pipeline_path, tasks_path, activity_path, settings_path].each do |url|
      get url
      assert_response :success, url
      assert_select 'title', text: /LeadCurrent/
      assert_no_match /Salesforce|Fixture|RailCRM/, response.body
    end
    get root_path
    assert_select '[data-stat=pipeline_value]', text: /USD/
    assert_select '[data-stat=pipeline_value]', text: /EUR/
  end
end
