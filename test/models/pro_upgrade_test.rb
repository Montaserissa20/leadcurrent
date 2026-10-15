require "test_helper"

class ProUpgradeTest < ActiveSupport::TestCase
  setup { @user = make_user }

  test "followups rank by urgency clear on completion and never satisfy first contact" do
    travel_to Time.zone.local(2026, 10, 15, 12) do
      lead = qualify(make_lead(@user))
      task = ScheduleFollowUp.call(lead, actor: @user, due_at: 1.hour.from_now)
      assert_equal 85, NextBestAction.new(@user).call.first.priority
      assert_equal :complete_task, NextBestAction.new(@user).call.first.action
      travel 2.hours
      recommendation = NextBestAction.new(@user).call.first
      assert_equal 95, recommendation.priority
      assert_equal task, recommendation.task
      assert_match "overdue", recommendation.reason
      first_contact = lead.reload.first_contact_at
      ManageTask.complete(task, actor: @user)
      assert_empty NextBestAction.new(@user).call
      assert_equal first_contact, lead.reload.first_contact_at
    end
  end

  test "automation boundary windows are deterministic and cleared by contact" do
    travel_to Time.zone.local(2026, 10, 15, 12) do
      lead = make_lead(@user, created_at: 20.hours.ago)
      assert_equal 90, NextBestAction.new(@user).call(record: lead).first.priority
      deal = make_opportunity(@user)
      deal.update!(last_activity_at: 72.hours.ago)
      assert_equal 80, NextBestAction.new(@user).call(record: deal).first.priority
      RecordActivity.call(deal, actor: @user, kind: "contact", body: "Completed meeting")
      assert_empty NextBestAction.new(@user).call(record: deal)
      deal.update!(expected_closing_date: 7.days.from_now.to_date)
      assert_equal :advance, NextBestAction.new(@user).call(record: deal).first.action
      RecordActivity.call(lead, actor: @user, kind: "contact", body: "Completed call")
      assert_empty NextBestAction.new(@user).call(record: lead)
    end
  end

  test "duplicate scheduled followup reuses pending task without duplicate audit" do
    lead = make_lead(@user)
    due = 1.day.from_now.change(usec: 0)
    task = ScheduleFollowUp.call(lead, actor: @user, due_at: due)
    assert_no_difference(["Task.count", "AuditEvent.count"]) do
      assert_equal task, ScheduleFollowUp.call(lead, actor: @user, due_at: due)
    end
    ManageTask.complete(task, actor: @user)
    assert_difference("Task.count", 1) { ScheduleFollowUp.call(lead, actor: @user, due_at: due) }
  end

  test "customer profile includes original lead conversation and moved tasks after conversion" do
    lead = qualify(make_lead(@user))
    task = ScheduleFollowUp.call(lead, actor: @user, due_at: 1.day.from_now)
    deal = convert(lead)
    RecordActivity.call(deal, actor: @user, kind: "note", body: "Proposal context")
    unrelated = make_opportunity(@user)
    profile = CustomerProfile.new(@user, deal)
    assert_equal [lead.id], profile.leads.pluck(:id)
    assert_equal [deal.id], profile.opportunities.pluck(:id)
    assert_equal ["Proposal context", "Completed discovery call"], profile.activities.map(&:body)
    assert_equal [task.id], profile.tasks.map(&:id)
    assert_not_includes profile.opportunities.pluck(:id), unrelated.id
    assert_raises(ActiveRecord::RecordNotFound) { CustomerProfile.new(make_user, deal) }
  end

  test "metrics aggregate currencies independently with real conversion and outcomes" do
    usd = make_opportunity(@user)
    usd.update!(value: 100)
    eur = convert(qualify(make_lead(@user)), value: 40, currency: "EUR")
    lost = make_opportunity(@user)
    lost.update!(value: 300)
    OpportunityTransition.call(lost, to: "lost", actor: @user)
    won = make_opportunity(@user)
    won.update!(value: 200)
    %w[proposal negotiation won].each { |stage| OpportunityTransition.call(won, to: stage, actor: @user) }
    make_lead(@user, created_at: 25.hours.ago)
    closed = make_lead(@user, created_at: 30.hours.ago)
    LeadTransition.call(closed, to: "disqualified", actor: @user)
    make_opportunity(make_user)
    metrics = SalesMetrics.new(@user)
    assert_equal({ "USD" => 100, "EUR" => 40 }, metrics.pipeline_values)
    assert_equal({ "USD" => 200 }, metrics.won_values)
    assert_equal 200, metrics.average_values["USD"]
    assert_equal 40, metrics.average_values["EUR"]
    assert_equal 2, metrics.statistics[:active_opportunities]
    assert_equal 1, metrics.statistics[:won_opportunities]
    assert_equal 1, metrics.statistics[:lost_opportunities]
    assert_equal 1, metrics.statistics[:overdue_contacts]
    assert_equal 66.7, metrics.statistics[:conversion_rate]
  end

  test "empty metrics handle zero denominators" do
    metrics = SalesMetrics.new(@user)
    assert_equal 0.0, metrics.statistics[:conversion_rate]
    assert_empty metrics.pipeline_values
    assert_empty metrics.average_values
  end

  test "task mutations reject foreign tenants colleagues stale owners and completed tasks" do
    salesperson = make_user(organization: @user.organization, role: "salesperson")
    lead = make_lead(@user)
    task = ScheduleFollowUp.call(lead, actor: @user, due_at: 1.day.from_now)
    assert_raises(WorkflowError) { ManageTask.complete(task, actor: salesperson) }
    assert_raises(ActiveRecord::RecordNotFound) { ManageTask.complete(task, actor: make_user) }
    ManageTask.update(task, actor: @user, title: "Send proposal", due_at: 2.days.from_now)
    assert_equal "Send proposal", task.reload.title
    assert_raises(WorkflowError) { ManageTask.update(task, actor: @user, title: "Bad", due_at: 1.hour.ago) }
    task.update!(owner: salesperson)
    assert_raises(WorkflowError) { ManageTask.complete(task, actor: salesperson) }
    ManageTask.complete(task, actor: @user)
    assert_raises(WorkflowError) { ManageTask.update(task, actor: @user, title: "Reopen", due_at: 3.days.from_now) }
    assert_nil lead.reload.first_contact_at
  end

  test "NBA query count does not grow with number of overdue followups" do
    query_count = lambda do
      queries = 0
      subscriber = ->(_name, _start, _finish, _id, data) { queries += 1 if data[:sql].match?(/\ASELECT/i) && !data[:cached] }
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { NextBestAction.new(@user).call }
      queries
    end
    travel_to Time.zone.local(2026, 10, 15, 12) do
      lead = qualify(make_lead(@user))
      ScheduleFollowUp.call(lead, actor: @user, due_at: 1.hour.from_now)
      before = query_count.call
      4.times { ScheduleFollowUp.call(qualify(make_lead(@user)), actor: @user, due_at: 1.hour.from_now) }
      assert_equal before, query_count.call
    end
  end

  test "today recommendations respect the user's day boundary rather than UTC" do
    @user.update!(time_zone: "Pacific Time (US & Canada)")
    travel_to Time.utc(2026, 10, 16, 0) do
      lead = qualify(make_lead(@user))
      task = ScheduleFollowUp.call(lead, actor: @user, due_at: Time.utc(2026, 10, 16, 3))
      entry = NextBestAction.new(@user, now: Time.now.utc).call.first
      assert_equal task, entry.task
      assert_match "today at 20:00", entry.reason
    end
  end

  test "stale task ownership never produces an unusable colleague record action" do
    salesperson = make_user(organization: @user.organization, role: "salesperson")
    lead = qualify(make_lead(@user))
    task = ScheduleFollowUp.call(lead, actor: @user, due_at: 1.hour.from_now)
    task.update!(owner: salesperson)
    assert_empty NextBestAction.new(salesperson).call
  end
end
