require "test_helper"
require_relative "../support/ai_test_support"

class AiAdviceTest < ActionDispatch::IntegrationTest
  include AiTestSupport
  setup { install_fake_groq; @user = make_user; @lead = make_lead(@user) }
  teardown { restore_fake_groq }

  def ask(record = @lead, mode: "analysis", question: "Analyze this customer", extra: {})
    url = record.is_a?(Lead) ? lead_ai_advice_path(record) : opportunity_ai_advice_path(record)
    post url, params: { mode: mode, question: question }.merge(extra)
  end

  test "authorized salesperson gets customer-specific analysis with no email or phone fields sent" do
    @user.update!(role: "salesperson")
    @lead.update!(notes: "Interested in subscriptions for 40 seats; budget not yet confirmed.")
    login(@user)
    ask
    assert_response :success
    assert_select "turbo-frame#ai_advice_lead_#{@lead.id} .ai-answer"
    assert_select ".ai-rule", text: /Priority 50/
    assert_equal "no-store", response.headers["Cache-Control"]
    data = JSON.parse(@ai_requests.sole.fetch("messages").last.fetch("content"))
    assert_includes data["customer_data"]["facts"]["lead_notes"], "40 seats"
    assert_includes data.to_json, "Atlas Industries"
    assert_not_includes data.to_json, @lead.contact.email
    assert_not_includes data.to_json, @user.email
    assert_not_includes response.body, @ai_api_key
  end

  test "manager can use all four functions for a lead and analyze an opportunity" do
    opportunity = make_opportunity(@user)
    login(@user)
    Ai::SalesAdvisor::MODES.each_key do |mode|
      ask(mode: mode)
      assert_response :success
      assert_select ".ai-answer", text: /AI-GENERATED/
      assert_select ".ai-history-notice", text: "No recorded activity history for this customer."
      assert_select ".ai-draft", count: mode == "draft" ? 1 : 0
    end
    ask(opportunity)
    assert_response :success
    assert_select "turbo-frame#ai_advice_opportunity_#{opportunity.id} .ai-answer"
    assert_equal 5, @ai_requests.length
  end

  test "anonymous and temporary-password accounts cannot request advice" do
    ask
    assert_redirected_to login_path
    assert_empty @ai_requests
    @user.update!(password_change_required: true)
    post login_path, params: { email: @user.email, password: "test-password-123" }
    assert_redirected_to edit_password_path
    ask
    assert_redirected_to edit_password_path
    assert_empty @ai_requests
  end

  test "foreign records return not found before any provider call for either role" do
    foreign_user = make_user
    foreign = [make_lead(foreign_user), make_opportunity(foreign_user)]
    foreign.first.update!(notes: "FOREIGN_PRIVATE_NOTE")
    %w[manager salesperson].each do |role|
      @user.update!(role: role)
      login(@user)
      foreign.each do |record|
        ask(record)
        assert_response :not_found
        assert_not_includes response.body, "FOREIGN_PRIVATE_NOTE"
        assert_empty @ai_requests
      end
    end
  end

  test "readable colleague records work but cannot acquire an invented official priority" do
    colleague = make_user(organization: @user.organization, role: "salesperson")
    login(colleague)
    ask
    assert_response :success
    assert_select ".ai-rule", text: /No eligible rule-based recommendation/
    assert_nil JSON.parse(@ai_requests.sole["messages"].last["content"])["customer_data"]["official_rule"]
  end

  test "submitted IDs and made-up context cannot replace the scoped path record" do
    foreign = make_lead(make_user)
    foreign.update!(notes: "DO_NOT_SEND_FOREIGN_DATA")
    login(@user)
    ask(extra: { lead_id: foreign.id, organization_id: foreign.organization_id, customer_context: { notes: "DO_NOT_SEND_SUBMITTED_CONTEXT" } })
    assert_response :success
    payload = @ai_requests.sole.to_json
    assert_not_includes payload, "DO_NOT_SEND_FOREIGN_DATA"
    assert_not_includes payload, "DO_NOT_SEND_SUBMITTED_CONTEXT"
    assert_includes payload, "Atlas Industries"
  end

  test "provider errors stay within the customer's response frame and never expose provider bodies" do
    login(@user)
    ENV.delete("GROQ_API_KEY")
    ask
    assert_response :service_unavailable
    assert_select "turbo-frame#ai_advice_lead_#{@lead.id} [role=alert]", text: /not configured/
    assert_empty @ai_requests
    ENV["GROQ_API_KEY"] = @ai_api_key
    @ai_exception = Net::ReadTimeout.new
    ask
    assert_response :gateway_timeout
    assert_select ".ai-error", text: /too long/
    @ai_exception = nil
    @ai_status = 429
    @ai_raw = "private-provider-text #{@ai_api_key}"
    ask
    assert_response :too_many_requests
    assert_not_includes response.body, "private-provider-text"
    assert_not_includes response.body, @ai_api_key
    @ai_status = 200
    @ai_raw = "broken-json"
    ask
    assert_response :bad_gateway
    assert_select ".ai-error", text: /invalid answer/
  end

  test "AI output is escaped and all functions leave every CRM table unchanged" do
    login(@user)
    opportunity = make_opportunity(@user)
    @ai_answer = { summary: '<script>window.aiInjected = true</script>', evidence_ids: %w[record], risks: ['<img src=x onerror="alert(1)">'], next_step: "Review manually", explanation: "No action was taken", assumptions: [], draft: "" }
    models = [Lead, Opportunity, Task, Activity, AuditEvent, User, Session, Organization, Company, Contact]
    before = models.to_h { |model| [model.name, model.order(:id).map(&:attributes)] }
    %w[analysis next_action summary].each do |mode|
      ask(opportunity, mode: mode)
      assert_response :success
      assert_select ".ai-answer script", count: 0
      assert_select ".ai-answer img", count: 0
      assert_includes response.body, "&lt;script&gt;"
    end
    @ai_answer[:draft] = "Review and copy this draft; it has not been sent."
    ask(opportunity, mode: "draft")
    assert_response :success
    assert_equal before, models.to_h { |model| [model.name, model.order(:id).map(&:attributes)] }
    assert_includes response.body, "not sent"
  end

  test "question validation and request throttles bound provider usage" do
    login(@user)
    ask(question: "x" * 601)
    assert_response :unprocessable_entity
    ask(mode: "invented_mode")
    assert_response :unprocessable_entity
    assert_empty @ai_requests
    5.times { ask; assert_response :success }
    ask
    assert_response :too_many_requests
    assert_equal 5, @ai_requests.length
    assert_select ".ai-error", text: /limit reached/
  end

  test "CSRF and question privacy apply to direct HTTP requests" do
    login(@user)
    previous = Ai::AdviceController.allow_forgery_protection
    previous_lead = LeadsController.allow_forgery_protection
    Ai::AdviceController.allow_forgery_protection = true
    LeadsController.allow_forgery_protection = true
    ask
    assert_response :unprocessable_entity
    assert_empty @ai_requests
    get lead_path(@lead)
    assert_response :success
    assert_select ".ai-panel form[action='#{lead_ai_advice_path(@lead)}']", count: 1
    assert_select 'meta[name="Content-Security-Policy"]', count: 0
    assert_match /script-src[^;]*'nonce-[^']+'/, response.headers["Content-Security-Policy"]
    token = Nokogiri::HTML(response.body).at_css('meta[name="csrf-token"]')["content"]
    post lead_ai_advice_path(@lead), params: { authenticity_token: token, mode: "analysis", question: "Review this record" }
    assert_response :success
    assert_equal 1, @ai_requests.length
    filtered = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(question: "sensitive sales question", groq_api_key: @ai_api_key)
    assert_equal ["[FILTERED]"] * 2, filtered.values
  ensure
    Ai::AdviceController.allow_forgery_protection = previous
    LeadsController.allow_forgery_protection = previous_lead
  end
end
