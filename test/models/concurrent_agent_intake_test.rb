require "test_helper"
require_relative "../support/agent_intake_test_support"

class ConcurrentAgentIntakeTest < ActiveSupport::TestCase
  include AgentIntakeTestSupport
  self.use_transactional_tests = false
  setup do
    raise "Test DB only" unless Rails.env.test? && ActiveRecord::Base.connection.select_value("SELECT current_database()") == "leadcurrent_test"
    @user = make_user
    @other_manager = make_user(organization: @user.organization)
    @organization = @user.organization
    @credential, = AgentCredential.issue!(actor: @user, name: "Concurrency fixture")
  end
  teardown do
    [AgentInquiry, AgentCredential, Session, AuditEvent, Task, Activity, Opportunity, Lead, Contact, Company, User].each do |model|
      if model == Session
        model.where(user_id: @organization.users.select(:id)).delete_all
      else
        model.where(organization_id: @organization.id).delete_all
      end
    end
    @organization.destroy!
  end
  def race
    ready, start, results = Queue.new, Queue.new, Queue.new
    workers = 2.times.map do |index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          begin
            results << yield(index)
          rescue WorkflowError, AgentIntake::Error => error
            results << error.class.name
          end
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    workers.each(&:value)
    2.times.map { results.pop }
  end
  test "concurrent identical submissions return one durable inquiry and one replay" do
    results = race do |_index|
      _inquiry, replayed = AgentIntake::Submit.call(credential: AgentCredential.find(@credential.id), payload: AgentIntake::Payload.new(inquiry_payload), idempotency_key: "concurrent-same-key-1234")
      replayed
    end
    assert_equal [false, true], results.sort_by { |value| value ? 1 : 0 }
    assert_equal 1, AgentInquiry.where(agent_credential: @credential).count
    assert_equal 0, Lead.where(organization: @organization).count
  end
  test "concurrent manager approval creates exactly one lead and one final decision" do
    inquiry, = AgentIntake::Submit.call(credential: @credential, payload: AgentIntake::Payload.new(inquiry_payload), idempotency_key: "concurrent-approval-1234")
    results = race do |index|
      actor = User.find(index.zero? ? @user.id : @other_manager.id)
      ReviewAgentInquiry.call(inquiry: AgentInquiry.find(inquiry.id), actor: actor, decision: "accept").status
    end
    assert_equal ["WorkflowError", "accepted"], results.sort
    assert_equal 1, Lead.where(organization: @organization).count
    assert_equal 1, Company.where(organization: @organization).count
    assert_equal 1, Contact.where(organization: @organization).count
    assert_equal 1, AuditEvent.where(organization: @organization, action: "agent_inquiry_accepted").count
    assert_equal "accepted", inquiry.reload.status
  end
end
