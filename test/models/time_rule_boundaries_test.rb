require "test_helper"

class TimeRuleBoundariesTest < ActiveSupport::TestCase
  setup { @user = make_user }

  test "four hour warning begins exactly twenty elapsed hours after lead creation" do
    start = Time.zone.local(2026, 10, 16, 9)
    travel_to(start) { @lead = make_lead(@user) }

    { -1.second => 50, 0.seconds => 90, 1.second => 90 }.each do |offset, priority|
      travel_to(start + 20.hours + offset) do
        entry = NextBestAction.new(@user).call(record: @lead).sole
        assert_equal priority, entry.priority, "warning boundary offset #{offset}"
        assert_equal :contact, entry.action
        assert_not @lead.reload.overdue?
      end
    end
  end

  test "inactivity begins exactly seventy two elapsed hours after the last activity" do
    start = Time.zone.local(2026, 10, 16, 9)
    travel_to(start) { @deal = make_opportunity(@user) }

    travel_to(start + 72.hours - 1.second) do
      assert_empty NextBestAction.new(@user).call(record: @deal)
    end
    [0.seconds, 1.second].each do |offset|
      travel_to(start + 72.hours + offset) do
        entry = NextBestAction.new(@user).call(record: @deal).sole
        assert_equal 80, entry.priority, "inactivity boundary offset #{offset}"
        assert_equal :follow_up, entry.action
        assert_match "No activity", entry.reason
      end
    end
  end
end
