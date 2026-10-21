require "test_helper"
require_relative "../support/page_agent_test_support"

class PageAgentProxyTest < ActionDispatch::IntegrationTest
  include PageAgentTestSupport
  setup { install_agent_fake;@user=make_user;@lead=make_lead(@user) }
  teardown { restore_agent_fake }
  def ask(path: "/leads/#{@lead.id}",body: agent_body,extra: {},headers: {})
    post "/agent/chat/completions",params:{agent_request:body,page_path:path}.merge(extra).to_json,headers:{"CONTENT_TYPE"=>"application/json"}.merge(headers)
  end
  test "panel is authenticated and absent from security password create and edit pages" do
    get login_path
    assert_select '#leadcurrent-agent',count:0
    login(@user)
    [root_path,leads_path,lead_path(@lead),opportunity_path(make_opportunity(@user))].each do |path|
      get path
      assert_response :success
      assert_select '#leadcurrent-agent[data-turbo-permanent]',count:1
      assert_select '#agent-panel',text:/LeadCurrent AI Copilot/
      assert_not response.body.include?(@agent_key)
    end
    [settings_path,edit_password_path,new_lead_path,edit_lead_path(@lead)].each do |path|
      get path
      assert_select '#leadcurrent-agent',count:0
    end
  end
  test "anonymous temporary-password and foreign workspace requests never reach Groq" do
    ask
    assert_redirected_to login_path
    assert_empty @agent_requests
    @user.update!(password_change_required:true)
    post login_path,params:{email:@user.email,password:'test-password-123'}
    ask
    assert_redirected_to edit_password_path
    assert_empty @agent_requests
    @user.update!(password_change_required:false)
    login(@user)
    foreign=make_lead(make_user)
    ask(path:lead_path(foreign))
    assert_response :not_found
    assert_empty @agent_requests
    foreign_opportunity=make_opportunity(foreign.owner)
    ask(path:opportunity_path(foreign_opportunity))
    assert_response :not_found
    assert_empty @agent_requests
  end
  test "both roles can use scoped tool transport without modifying any CRM table" do
    @user.update!(role:'salesperson')
    login(@user)
    models=[Lead,Opportunity,Task,Activity,AuditEvent,User,Session,Organization,Company,Contact]
    before=models.to_h { |model| [model.name,model.order(:id).map(&:attributes)] }
    ask
    assert_response :success
    assert_equal 'no-store',response.headers['Cache-Control']
    json=response.parsed_body
    assert_equal 'AgentOutput',json.dig('choices',0,'message','tool_calls',0,'function','name')
    assert_not response.body.include?(@agent_key)
    assert_equal before,models.to_h { |model| [model.name,model.order(:id).map(&:attributes)] }
    @user.update!(role:'manager')
    ask
    assert_response :success
  end
  test "arbitrary endpoint options unsupported paths methods and oversized bodies are refused" do
    login(@user)
    ['/settings','/settings/password','https://evil.test','//evil.test','/leads/new','/leads/1/edit','/leads/1?workspace=999'].each do |path|
      ask(path:path)
      assert_response :unprocessable_entity
    end
    ask(extra:{target_url:'https://evil.test'})
    assert_response :unprocessable_entity
    ask(body:agent_body.merge('apiKey'=>'never-use-browser-keys'))
    assert_response :unprocessable_entity
    ask(body:agent_body('x'*28001))
    assert_response :unprocessable_entity
    get '/agent/chat/completions'
    assert_response :not_found
    put '/agent/chat/completions'
    assert_response :not_found
    post '/agent/chat/completions',params:'not json',headers:{'CONTENT_TYPE'=>'application/json'}
    assert_response :unprocessable_entity
    assert_empty @agent_requests
  end
  test "safe configuration quota timeout and invalid-tool errors are JSON and never expose provider text" do
    login(@user)
    ENV.delete('GROQ_API_KEY')
    ask
    assert_response :service_unavailable
    assert_equal 'configuration',response.parsed_body.dig('error','code')
    ENV['GROQ_API_KEY']=@agent_key
    @agent_status=429;@agent_raw="private-provider #{@agent_key}"
    ask
    assert_response :too_many_requests
    assert_not response.body.include?('private-provider')
    assert_not response.body.include?(@agent_key)
    @agent_status=200;@agent_exception=Net::ReadTimeout.new
    ask
    assert_response :gateway_timeout
    @agent_exception=nil;@agent_raw=nil;@agent_action={'execute_javascript'=>{'script'=>'fetch("https://evil.test")'}}
    ask
    assert_response :bad_gateway
    assert_equal 'invalid_response',response.parsed_body.dig('error','code')
  end
  test "CSRF protection and full request parameter filtering are preserved" do
    login(@user)
    previous=PageAgent::CompletionsController.allow_forgery_protection
    previous_lead=LeadsController.allow_forgery_protection
    PageAgent::CompletionsController.allow_forgery_protection=true
    LeadsController.allow_forgery_protection=true
    ask
    assert_response :unprocessable_entity
    assert_empty @agent_requests
    get lead_path(@lead)
    token=Nokogiri::HTML(response.body).at_css('meta[name=csrf-token]')['content']
    ask(headers:{'X-CSRF-Token'=>token})
    assert_response :success
    filtered=ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(agent_request:{messages:[{content:'private customer note'}]},groq_api_key:@agent_key)
    assert_equal ['[FILTERED]']*2,filtered.values
  ensure
    PageAgent::CompletionsController.allow_forgery_protection=previous
    LeadsController.allow_forgery_protection=previous_lead
  end
  test "company search and overdue ordering remain scoped and use the existing deadline" do
    older=make_lead(@user,created_at:30.hours.ago)
    newer=make_lead(@user,created_at:26.hours.ago)
    foreign=make_lead(make_user,created_at:40.hours.ago)
    login(@user)
    get leads_path,params:{attention:'overdue'}
    assert_response :success
    links=Nokogiri::HTML(response.body).css('tbody .record-title').map{|node|node['href']}
    assert_equal [lead_path(older),lead_path(newer)],links
    assert_not_includes links,lead_path(foreign)
    @lead.update!(title:'Unrelated title')
    get leads_path,params:{q:@lead.company.name}
    assert_select "a.record-title[href='#{lead_path(@lead)}']"
    get leads_path,params:{q:'%'}
    assert_select 'tbody .record-title',count:0
    assert_equal @lead.created_at+24.hours,@lead.first_contact_deadline
  end
end
