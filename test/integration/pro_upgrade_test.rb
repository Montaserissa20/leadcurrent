require "test_helper"

class ProUpgradeFlowTest < ActionDispatch::IntegrationTest
  setup { @user = make_user; login(@user) }

  test "customer workspace task create edit complete and filters persist without status changes" do
    lead = make_lead(@user)
    post tasks_path, params: { record_type: "Lead", record_id: lead.id, task: { title: "Prepare call", due_at: 1.day.from_now.iso8601, owner_id: make_user.id } }
    assert_redirected_to lead_path(lead)
    task = lead.tasks.last
    assert_equal @user.id, task.owner_id
    get edit_task_path(task)
    assert_response :success
    patch task_path(task), params: { task: { title: "Discuss proposal", due_at: 2.days.from_now.iso8601, completed_at: Time.current } }
    assert_equal "Discuss proposal", task.reload.title
    assert_nil task.completed_at
    get tasks_path(status: "pending", q: "Discuss")
    assert_select "[data-task-id='#{task.id}']"
    post complete_task_path(task), params: { from_profile: "true" }
    assert_redirected_to lead_path(lead)
    assert task.reload.completed_at
    assert_equal "new", lead.reload.status
    assert_nil lead.first_contact_at
    get tasks_path(status: "pending")
    assert_select "[data-task-id='#{task.id}']", count: 0
    get tasks_path(status: "completed")
    assert_select "[data-task-id='#{task.id}']"
  end

  test "NBA task and stage actions return to updated dashboard" do
    travel_to Time.zone.local(2026, 10, 15, 12) do
      lead = qualify(make_lead(@user))
      task = ScheduleFollowUp.call(lead, actor: @user, due_at: 1.hour.from_now)
      get root_path
      assert_select '.recommendation', text: /Follow-up due today/
      post complete_task_path(task), params: { from_dashboard: "true" }
      assert_redirected_to root_path
      follow_redirect!
      assert_select '.recommendation', count: 0
      deal = make_opportunity(@user)
      deal.update!(expected_closing_date: Date.current)
      post transition_opportunity_path(deal), params: { status: "proposal", from_dashboard: "true" }
      assert_redirected_to root_path
      assert_equal "proposal", deal.reload.status
    end
  end

  test "profile shows original conversations and connected opportunity after conversion" do
    deal = make_opportunity(@user)
    task = ScheduleFollowUp.call(deal, actor: @user, due_at: 1.day.from_now)
    get opportunity_path(deal)
    assert_response :success
    assert_select '.customer-card', text: /Sam Taylor/
    assert_select '.timeline-item', text: /Completed discovery call/
    get lead_path(deal.lead)
    assert_select "a[href='#{opportunity_path(deal)}']", text: deal.title
    get tasks_path(contact_id: deal.contact_id)
    assert_select "[data-task-id='#{task.id}']"
    get analytics_path
    assert_response :success
    assert_select '[data-metric=conversion]', text: '100.0%'
    assert_select '[data-stage-metric=qualification]', text: /1/
  end

  test "foreign task create edit update complete and profiles remain protected" do
    foreign = make_lead(make_user)
    post tasks_path, params: { record_type: "Lead", record_id: foreign.id, task: { title: "Bad", due_at: 1.day.from_now.iso8601 } }
    assert_response :not_found
    task = ScheduleFollowUp.call(foreign, actor: foreign.owner, due_at: 1.day.from_now)
    get edit_task_path(task)
    assert_response :not_found
    patch task_path(task), params: { task: { title: "Bad", due_at: 1.day.from_now.iso8601 } }
    assert_response :not_found
    post complete_task_path(task)
    assert_response :not_found
    get tasks_path(lead_id: foreign.id)
    assert_response :not_found
    get tasks_path(contact_id: foreign.contact_id)
    assert_response :not_found
    get analytics_path
    assert_select '[data-metric=active_opportunities] strong', text: "0"
  end

  test "activity methods notes and search filters reflect recorded interactions" do
    lead = make_lead(@user)
    post actions_path, params: { record_type: "Lead", record_id: lead.id, action_kind: "contact", contact_method: "meeting", body: "Discovery discussion" }
    assert_equal "[Meeting] Discovery discussion", lead.activities.last.body
    post actions_path, params: { record_type: "Lead", record_id: lead.id, action_kind: "note", body: "Budget approved" }
    get activity_path(kind: "note", q: "Budget")
    assert_select '.timeline-item', count: 1, text: /Budget approved/
    assert_select '.timeline-item', text: /Discovery discussion/, count: 0
    assert_no_difference('Activity.count') { post actions_path, params: { record_type: "Lead", record_id: lead.id, action_kind: "contact", contact_method: "email-send", body: "Invalid" } }
    assert_response :unprocessable_entity
  end

  test "active and overdue dashboard filters select matching rows" do
    active = make_opportunity(@user)
    closed = make_opportunity(@user)
    OpportunityTransition.call(closed, to: "lost", actor: @user)
    overdue = make_lead(@user, created_at: 25.hours.ago)
    fresh = make_lead(@user)
    get opportunities_path(status: "active", q: "Enterprise")
    assert_select "a[href='#{opportunity_path(active)}']"
    assert_select "a[href='#{opportunity_path(closed)}']", count: 0
    get leads_path(attention: "overdue")
    assert_select "a[href='#{lead_path(overdue)}']"
    assert_select "a[href='#{lead_path(fresh)}']", count: 0
  end
end
