require "test_helper"
class NextBestActionTest < ActiveSupport::TestCase
  setup { @user = make_user }
  test "deterministic ranking explains overdue upcoming inactive closing and new records" do
    travel_to Time.zone.local(2026, 10, 14, 12) do
      overdue = make_lead(@user, created_at: 29.hours.ago)
      urgent = make_lead(@user, created_at: 22.hours.ago)
      fresh = make_lead(@user)
      inactive = make_opportunity(@user)
      inactive.update!(last_activity_at: 80.hours.ago)
      closing = make_opportunity(@user)
      closing.update!(expected_closing_date: 2.days.from_now.to_date)
      entries = NextBestAction.new(@user).call
      assert_equal [overdue.id, urgent.id, inactive.id, closing.id, fresh.id], entries.map { |entry| entry.record.id }
      assert_equal [100, 90, 80, 70, 50], entries.map(&:priority)
      assert_equal "First contact overdue by 5.0 hours", entries.first.reason
      assert_equal "First contact deadline in 2.0 hours", entries[1].reason
      assert_equal "No activity for 80.0 hours", entries[2].reason
      assert_match "Expected close", entries[3].reason
      assert entries.all? { |entry| entry.reason.present? && entry.action.present? }
    end
  end
  test "completed contacts closed deals and pending followups remove fulfilled suggestions" do
    lead = make_lead(@user)
    RecordActivity.call(lead, actor: @user, kind: "contact", body: "Call", follow_up_at: 1.day.from_now)
    inactive = make_opportunity(@user)
    inactive.update!(last_activity_at: 80.hours.ago)
    ScheduleFollowUp.call(inactive, actor: @user, due_at: 1.day.from_now)
    lost = make_opportunity(@user)
    OpportunityTransition.call(lost, to: "lost", actor: @user)
    assert_empty NextBestAction.new(@user).call
  end
  test "tenant and owner separation applies without an AI provider" do
    colleague = make_user(organization: @user.organization, role: "salesperson")
    own = make_lead(colleague)
    make_lead(@user)
    foreign = make_lead(make_user)
    assert_equal [own.id], NextBestAction.new(colleague).call.map { |entry| entry.record.id }
    assert_not_includes NextBestAction.new(@user).call.map { |entry| entry.record.id }, foreign.id
  end
  test "stable deadline order resolves tied priority" do
    travel_to Time.zone.local(2026, 10, 14, 12) do
      newer = make_lead(@user, created_at: 26.hours.ago)
      older = make_lead(@user, created_at: 30.hours.ago)
      assert_equal [older.id, newer.id], NextBestAction.new(@user).call.map { |entry| entry.record.id }
    end
  end
end
