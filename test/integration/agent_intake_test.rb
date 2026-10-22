require "test_helper"
require_relative "../support/agent_intake_test_support"

class AgentIntakeHttpTest < ActionDispatch::IntegrationTest
  include AgentIntakeTestSupport
  setup do
    @manager = make_user
    @salesperson = make_user(organization: @manager.organization, role: "salesperson")
    @foreign = make_user
    @credential, @token = AgentCredential.issue!(actor: @manager, name: "Test intake")
    AgentIntake::RequestGate::STORE.clear
  end
  teardown { AgentIntake::RequestGate::STORE.clear }

  def submit(data = inquiry_payload, token: @token, key: SecureRandom.hex(16), raw: nil, headers: {})
    post "/api/v1/agent_inquiries", params: raw || JSON.generate(data), headers: { "CONTENT_TYPE" => "application/json", "HTTP_AUTHORIZATION" => token ? "Bearer #{token}" : "", "HTTP_IDEMPOTENCY_KEY" => key }.merge(headers)
  end

  test "only active bearer authentication works and browser session cookies do not substitute" do
    login(@manager)
    submit(token: nil)
    assert_response :unauthorized
    assert_equal "unauthorized", response.parsed_body.dig("error", "code")
    submit(token: "not-a-credential")
    assert_response :unauthorized
    @credential.revoke!(actor: @manager)
    submit
    assert_response :unauthorized
    expired, expired_token = AgentCredential.issue!(actor: @manager, name: "Expired", expires_at: 1.minute.from_now)
    expired.update_column(:expires_at, 1.second.ago)
    submit(token: expired_token)
    assert_response :unauthorized
    assert_equal 0, AgentInquiry.count
    assert_not response.body.include?(@token)
    assert_not response.body.include?("password_digest")
  end

  test "valid JSON persists only an unverified inquiry in the credential workspace with safe receipt and durable retries" do
    baseline = [Lead, Company, Contact, Opportunity, Activity, Task].map(&:count)
    submit(key: "durable-http-key-12345")
    assert_response :created
    body = response.parsed_body
    assert_equal %w[identity inquiry_id replayed status], body.keys.sort
    assert_equal "unverified", body["identity"]
    assert_equal "pending_review", body["status"]
    inquiry = AgentInquiry.find(body["inquiry_id"])
    assert_equal @manager.organization_id, inquiry.organization_id
    assert_equal baseline, [Lead, Company, Contact, Opportunity, Activity, Task].map(&:count)
    submit(key: "durable-http-key-12345")
    assert_response :ok
    assert response.parsed_body["replayed"]
    assert_equal 1, AgentInquiry.count
    submit(inquiry_payload(quantity: 51), key: "durable-http-key-12345")
    assert_response :conflict
    assert_equal "idempotency_conflict", response.parsed_body.dig("error", "code")
    assert_equal 1, AgentInquiry.count
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  test "strict API rejects tenancy decision fields malformed duplicate and invalid typed input" do
    [inquiry_payload(organization_id: @foreign.organization_id), inquiry_payload(status: "accepted"), inquiry_payload(quantity: true), inquiry_payload(contact_email: "invalid"), inquiry_payload(message: @token)].each do |data|
      submit(data)
      assert_response :unprocessable_entity
      assert_not response.body.include?(@token)
    end
    submit(raw: "{broken")
    assert_response :bad_request
    submit(raw: '{"company_name":"A","company_name":"B"}')
    assert_response :bad_request
    submit(key: "short")
    assert_response :bad_request
    assert_equal 0, AgentInquiry.count
  end

  test "body limit media type unsupported methods and query credentials fail with bounded JSON before normal parsing" do
    submit(raw: "x" * 16_385)
    assert_response :content_too_large
    assert_equal "request_too_large", response.parsed_body.dig("error", "code")
    submit(headers: { "CONTENT_TYPE" => "text/plain" })
    assert_response :unsupported_media_type
    get "/api/v1/agent_inquiries"
    assert_response :method_not_allowed
    assert_equal "POST", response.headers["Allow"]
    post "/api/v1/agent_inquiries?organization_id=#{@foreign.organization_id}", params: "{}", headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :bad_request
    assert_equal 0, AgentInquiry.count
  end

  test "API limits credential and unauthenticated source request rates without duplicate storage" do
    10.times do
      submit(key: "rate-check-same-key-123")
      assert_includes [200, 201], response.status
    end
    submit(key: "rate-check-same-key-123")
    assert_response :too_many_requests
    assert_equal "60", response.headers["Retry-After"]
    assert_equal 1, AgentInquiry.count
    AgentIntake::RequestGate::STORE.clear
    60.times { submit(token: nil) }
    submit(token: nil)
    assert_response :too_many_requests
  end

  test "missing optional contact fields remain pending and cannot be accepted into an invalid lead" do
    submit(inquiry_payload(contact_name: nil, contact_email: nil))
    assert_response :created
    inquiry = AgentInquiry.find(response.parsed_body["inquiry_id"])
    login(@manager)
    post review_agent_inquiry_path(inquiry), params: { decision: "accept" }
    assert_response :unprocessable_entity
    assert_equal "pending_review", inquiry.reload.status
    assert_nil inquiry.accepted_lead_id
  end

  test "inbox is workspace scoped read-only for salespeople and review is manager only" do
    inquiry = make_inquiry(@manager)
    foreign = make_inquiry(@foreign)
    login(@salesperson)
    get agent_inquiries_path
    assert_response :success
    assert_select "a[href=?]", agent_inquiry_path(inquiry)
    assert_select "a[href=?]", agent_inquiry_path(foreign), count: 0
    get agent_inquiry_path(foreign)
    assert_response :not_found
    post review_agent_inquiry_path(inquiry), params: { decision: "accept", owner_id: @salesperson.id }
    assert_response :forbidden
    post analyze_agent_inquiry_path(inquiry)
    assert_response :forbidden
    get agent_credentials_path
    assert_response :forbidden
    assert_equal "pending_review", inquiry.reload.status
  end

  test "manager acceptance rechecks tenant owner and status and lead shows its unverified source" do
    inquiry = make_inquiry(@manager)
    login(@manager)
    post review_agent_inquiry_path(inquiry), params: { decision: "accept", owner_id: @foreign.id }
    assert_response :not_found
    assert_equal "pending_review", inquiry.reload.status
    post review_agent_inquiry_path(inquiry), params: { decision: "accept", owner_id: @salesperson.id, organization_id: @foreign.organization_id, status: "won" }
    assert_redirected_to lead_path(inquiry.reload.accepted_lead_id)
    lead = inquiry.accepted_lead
    assert_equal @salesperson.id, lead.owner_id
    assert_equal "new", lead.status
    assert_nil lead.first_contact_at
    get lead_path(lead)
    assert_select ".inquiry-origin", text: /Identity|identity/
    assert_select "a[href=?]", agent_inquiry_path(inquiry), text: "Review source inquiry →"
    assert_no_difference "Lead.count" do
      post review_agent_inquiry_path(inquiry), params: { decision: "accept" }
    end
    assert_response :unprocessable_entity
    login(@foreign)
    post review_agent_inquiry_path(inquiry), params: { decision: "reject" }
    assert_response :not_found
  end

  test "credential UI returns secret once with no-store and never renders it on index or audit" do
    login(@manager)
    post agent_credentials_path, params: { agent_credential: { name: "One-time test", organization_id: @foreign.organization_id, token_digest: "not permitted" } }
    assert_response :created
    token = css_select("#agent-issued-token").first.text
    assert_match AgentCredential::TOKEN_PATTERN, token
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_select 'meta[name="turbo-cache-control"][content="no-cache"]'
    issued = AgentCredential.authenticate(token)
    assert_equal @manager.organization_id, issued.organization_id
    get agent_credentials_path
    assert_response :success
    assert_not response.body.include?(token)
    post revoke_agent_credential_path(issued)
    assert_redirected_to agent_credentials_path
    assert_nil AgentCredential.authenticate(token)
    assert_not AuditEvent.all.pluck(:details).to_json.include?(token)
  end

  test "browser credentials and review preserve CSRF mandatory password and anonymous guards" do
    inquiry = make_inquiry(@manager)
    get agent_inquiries_path
    assert_redirected_to login_path
    login(@manager)
    original = AgentInquiriesController.allow_forgery_protection
    original_credentials = AgentCredentialsController.allow_forgery_protection
    AgentInquiriesController.allow_forgery_protection = true
    AgentCredentialsController.allow_forgery_protection = true
    post review_agent_inquiry_path(inquiry), params: { decision: "reject" }
    assert_response :unprocessable_entity
    assert_equal "pending_review", inquiry.reload.status
    assert_no_difference "AgentCredential.count" do
      post agent_credentials_path, params: { agent_credential: { name: "CSRF" } }
    end
    assert_response :unprocessable_entity
    submit
    assert_response :created
    @manager.update!(password_change_required: true)
    get agent_inquiries_path
    assert_redirected_to edit_password_path
  ensure
    AgentInquiriesController.allow_forgery_protection = original
    AgentCredentialsController.allow_forgery_protection = original_credentials
  end

  test "inquiry bodies and arbitrary rejected input cannot enter Rails parameter logs" do
    capture = StringIO.new
    old_logger = Rails.logger
    Rails.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(capture))
    submit(inquiry_payload(message: "PRIVATE_INTAKE_CANARY"))
    assert_response :created
    submit(inquiry_payload(unexpected_private_field: "PRIVATE_UNKNOWN_CANARY"))
    assert_response :unprocessable_entity
    assert_not capture.string.include?("PRIVATE_INTAKE_CANARY")
    assert_not capture.string.include?("PRIVATE_UNKNOWN_CANARY")
    assert_not capture.string.include?(@token)
  ensure
    Rails.logger = old_logger
  end
end
