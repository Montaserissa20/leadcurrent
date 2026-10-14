require "test_helper"
class ConcurrentConversionTest < ActiveSupport::TestCase
  self.use_transactional_tests = false
  setup do
    @user = make_user
    @organization = @user.organization
    @lead = qualify(make_lead(@user))
  end
  teardown do
    # Only records created by this test, in the test database.
    [Session, AuditEvent, Task, Activity, Opportunity, Lead, Contact, Company, User].each do |model|
      if model == Session
        model.where(user_id: @organization.users.select(:id)).delete_all
      else
        model.where(organization_id: @organization.id).delete_all
      end
    end
    @organization.destroy!
  end
  test "two simultaneous conversions produce one opportunity and one rejection" do
    ready, start, results = Queue.new, Queue.new, Queue.new
    workers = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          lead = Lead.find(@lead.id)
          actor = User.find(@user.id)
          ready << true
          start.pop
          begin
            results << convert(lead, actor: actor).class.name
          rescue WorkflowError => error
            results << error.class.name
          end
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    workers.each(&:value)
    assert_equal %w[Opportunity WorkflowError], 2.times.map { results.pop }.sort
    assert_equal 1, Opportunity.where(lead_id: @lead.id).count
    assert_equal "converted", @lead.reload.status
  end
end
