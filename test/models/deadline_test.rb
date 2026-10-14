require "test_helper"
class DeadlineTest < ActiveSupport::TestCase
  setup { @user = make_user }
  test "deadline is persisted exactly 24 elapsed hours after creation" do
    travel_to Time.zone.local(2026, 10, 14, 9, 0, 0) do
      lead = make_lead(@user)
      assert_equal Time.current + 24.hours, lead.reload.first_contact_deadline
      assert_equal 86400, lead.first_contact_deadline - lead.created_at
      assert_not lead.overdue?
    end
  end
  test "before exact and after deadline boundaries agree with database scope" do
    start = Time.zone.local(2026, 10, 14, 9)
    travel_to(start) { @lead = make_lead(@user) }
    travel_to(start + 24.hours - 1.second) { assert_not @lead.overdue?; assert_not Lead.overdue.exists?(@lead.id) }
    travel_to(start + 24.hours) { assert_not @lead.overdue?; assert_not Lead.overdue.exists?(@lead.id) }
    travel_to(start + 24.hours + 1.second) { assert @lead.overdue?; assert Lead.overdue.exists?(@lead.id) }
  end
  test "completed qualifying contact clears overdue condition and records timestamp" do
    start = Time.zone.local(2026, 10, 14, 9)
    travel_to(start) { @lead = make_lead(@user) }
    travel_to(start + 25.hours) do
      assert @lead.overdue?
      activity = RecordActivity.call(@lead, actor: @user, kind: "contact", body: "Completed phone call")
      assert_equal Time.current, activity.completed_at
      assert_equal Time.current, @lead.reload.first_contact_at
      assert_equal "contacted", @lead.status
      assert_not @lead.overdue?
      assert_not Lead.overdue.exists?(@lead.id)
    end
  end
  test "note scheduled task and task completion are not completed first contact" do
    travel_to Time.zone.local(2026, 10, 14, 9) do
      lead = make_lead(@user, created_at: 25.hours.ago)
      RecordActivity.call(lead, actor: @user, kind: "note", body: "Plan to call")
      task = ScheduleFollowUp.call(lead, actor: @user, due_at: 1.day.from_now)
      task.update!(completed_at: Time.current)
      assert_nil lead.reload.first_contact_at
      assert lead.overdue?
    end
  end
  test "timezone midnight and daylight saving change preserve elapsed hours" do
    Time.use_zone("Europe/Istanbul") do
      travel_to(Time.zone.local(2026, 10, 14, 23, 30)) { @lead = make_lead(@user) }
      Time.use_zone("UTC") do
        travel_to(@lead.created_at + 24.hours) { assert_not @lead.overdue? }
        travel_to(@lead.created_at + 24.hours + 1.second) { assert @lead.overdue? }
      end
    end
    Time.use_zone("Eastern Time (US & Canada)") do
      travel_to Time.zone.local(2026, 3, 7, 12) do
        lead = make_lead(@user)
        assert_equal 86400, lead.first_contact_deadline - lead.created_at
        assert_equal 13, lead.first_contact_deadline.in_time_zone.hour
      end
    end
  end
  test "first contact time remains the first completed contact" do
    travel_to(Time.zone.local(2026, 10, 14, 9)) do
      @lead = make_lead(@user)
      RecordActivity.call(@lead, actor: @user, kind: "contact", body: "First call")
      @first = Time.current
    end
    travel_to @first + 1.hour do
      RecordActivity.call(@lead, actor: @user, kind: "contact", body: "Second call")
      assert_equal @first, @lead.reload.first_contact_at
    end
  end
end
