require "test_helper"
require "yaml"

class AgentIntegrationsTest < ActionDispatch::IntegrationTest
  def spec = AgentIntegrationGuide.specification
  def operation = spec.fetch("paths").fetch(api_v1_agent_inquiries_path).fetch("post")

  test "public integration center and discovery expose only static instructions" do
    manager = make_user
    credential, token = AgentCredential.issue!(actor: manager, name: "Private integration marker")
    get agent_integrations_path
    assert_response :success
    assert_select "h1", text: "Agent Integrations"
    assert_select 'link[rel="service-desc"][href=?]', agent_inquiries_openapi_path
    assert_includes response.headers["Link"], 'rel="service-desc"'
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_select "#integration-endpoint", text: "http://www.example.com#{api_v1_agent_inquiries_path}"
    assert_select 'button[data-action="integration-copy#copy"]', count: 4
    assert_select 'input', count: 0
    [token, credential.token_digest, credential.name, manager.email, manager.organization.name, ENV["GROQ_API_KEY"]].compact.reject(&:empty?).each do |secret|
      assert_not_includes response.body, secret
    end
    assert_not response.headers.key?("Access-Control-Allow-Origin")
    assert_not_includes response.body, "data-controller=\"page-agent\""
    assert_includes response.body, "YOUR_AGENT_TOKEN"
    assert_includes response.body, "No internal Copilot or Page Agent required."
  end

  test "OpenAPI download is public and is the exact checked-in specification" do
    get agent_inquiries_openapi_path
    assert_response :success
    assert_equal File.binread(AgentIntegrationGuide::SPEC_PATH), response.body.b
    assert_includes response.media_type, "application/yaml"
    assert_includes response.headers["Content-Disposition"], 'attachment;'
    assert_includes response.headers["Content-Disposition"], "agent-inquiries.openapi.yaml"
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
    assert_equal "3.1.0", YAML.safe_load(response.body).fetch("openapi")
    assert_not response.headers.key?("Access-Control-Allow-Origin")
    assert_equal [api_v1_agent_inquiries_path], spec.fetch("paths").keys
    assert_equal ["post"], spec.fetch("paths").values.first.keys
  end

  test "contract matches actual route fields bounds scopes statuses and error codes" do
    recognized = Rails.application.routes.recognize_path(api_v1_agent_inquiries_path, method: :post)
    assert_equal "api/v1/agent_inquiries", recognized[:controller]
    assert_equal "create", recognized[:action]
    assert_equal [{"agentBearer" => []}], operation.fetch("security")
    assert_equal "bearer", spec.dig("components", "securitySchemes", "agentBearer", "scheme")
    parameter = operation.fetch("parameters").sole
    assert_equal ["Idempotency-Key", "header", true], parameter.values_at("name", "in", "required")
    assert_equal [16, 100], parameter.fetch("schema").values_at("minLength", "maxLength")
    schema = spec.dig("components", "schemas", "InquiryRequest")
    assert_equal AgentIntake::Payload::FIELDS.sort, schema.fetch("properties").keys.sort
    assert_equal %w[company_name message product_or_service], schema.fetch("required").sort
    assert_equal false, schema.fetch("additionalProperties")
    AgentIntake::Payload::LENGTHS.each do |name, limit|
      assert_equal limit, schema.dig("properties", name, "maxLength"), name
    end
    assert_equal 1_000_000, schema.dig("properties", "quantity", "maximum")
    assert_equal AgentInquiry::STATUSES, spec.dig("components", "schemas", "InquiryReceipt", "properties", "status", "enum")
    assert_equal %w[identity inquiry_id replayed status], spec.dig("components", "schemas", "InquiryReceipt", "required").sort
    assert_equal "unverified", spec.dig("components", "schemas", "InquiryReceipt", "properties", "identity", "const")
    assert_equal %w[200 201 400 401 405 409 413 415 422 429 503], operation.fetch("responses").keys.sort
    errors = spec.dig("components", "schemas", "ApiError", "properties", "error", "properties", "code", "enum")
    assert_empty AgentIntake::Error::ERRORS.keys.map(&:to_s) - errors
    AgentIntake::Error::ERRORS.each do |code, (status, message)|
      response = operation.fetch("responses").fetch(status.to_s).to_json
      assert_includes response, code.to_s
      assert_includes response, message
    end
    assert_equal "60", operation.dig("responses", "429", "headers", "Retry-After", "schema", "const")
    assert_includes operation.fetch("description"), AgentInquiryIngress::MAX_BYTES.to_s
  end

  test "published fictional example submits through actual API and replays without creating CRM data" do
    user = make_user
    credential, token = AgentCredential.issue!(actor: user, name: "Documented example test")
    AgentIntake::RequestGate::STORE.clear
    payload = operation.dig("requestBody", "content", "application/json", "example")
    key = "openapi-example-#{SecureRandom.hex(10)}"
    headers = { "CONTENT_TYPE" => "application/json", "HTTP_AUTHORIZATION" => "Bearer #{token}", "HTTP_IDEMPOTENCY_KEY" => key }
    assert_no_difference ["Lead.count", "Opportunity.count", "Contact.count", "Company.count"] do
      assert_difference "AgentInquiry.count", 1 do
        post api_v1_agent_inquiries_path, params: JSON.generate(payload), headers: headers
        assert_response :created
      end
      receipt = response.parsed_body
      assert_equal %w[identity inquiry_id replayed status], receipt.keys.sort
      assert_equal ["pending_review", "unverified", false], receipt.values_at("status", "identity", "replayed")
      inquiry = AgentInquiry.find(receipt.fetch("inquiry_id"))
      assert_equal credential.organization_id, inquiry.organization_id
      post api_v1_agent_inquiries_path, params: JSON.generate(payload), headers: headers
      assert_response :success
      assert_equal receipt.fetch("inquiry_id"), response.parsed_body.fetch("inquiry_id")
      assert_equal true, response.parsed_body.fetch("replayed")
    end
  ensure
    AgentIntake::RequestGate::STORE.clear
  end

  test "public documents do not open private credential review or bearer routes" do
    get agent_integrations_path
    get agent_credentials_path
    assert_redirected_to login_path
    post agent_credentials_path, params: { agent_credential: { name: "Not authorized" } }
    assert_redirected_to login_path
    salesperson = make_user(role: "salesperson")
    login(salesperson)
    get agent_integrations_path
    assert_response :success
    get agent_credentials_path
    assert_response :forbidden
    post agent_credentials_path, params: { agent_credential: { name: "Not authorized" } }
    assert_response :forbidden
    post api_v1_agent_inquiries_path, params: "{}", headers: {"CONTENT_TYPE" => "application/json"}
    assert_response :unauthorized
    assert_equal "unauthorized", response.parsed_body.dig("error", "code")
  end

  test "examples have correct paths headers no real secrets and reject code-shaped origins" do
    guide = AgentIntegrationGuide.new(base_url: "https://leadcurrent-production.up.railway.app")
    assert_equal %w[curl powershell python], guide.examples.keys
    guide.examples.each_value do |code|
      assert_includes code, api_v1_agent_inquiries_path
      assert_includes code, "Authorization"
      assert_includes code, "Idempotency-Key"
      assert_includes code, "LEADCURRENT_AGENT_TOKEN"
      refute_match AgentCredential::TOKEN_PATTERN, code
      refute_match /\bgsk_[A-Za-z0-9_-]{20,}/, code
      assert_not_includes code, "GROQ_API_KEY"
    end
    assert_includes guide.examples.fetch("curl"), "\\\n"
    ["http://127.0.0.1:3100';evil", "http://$(evil)", "https://example.test/path", "https://user:secret@example.test"].each do |origin|
      assert_raises(ArgumentError) { AgentIntegrationGuide.new(base_url: origin) }
    end
  end
end
