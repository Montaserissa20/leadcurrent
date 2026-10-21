require "test_helper"
require_relative "../support/page_agent_test_support"

class CopilotHttpTest < ActionDispatch::IntegrationTest
  include PageAgentTestSupport
  setup { install_agent_fake;Copilot::Conversation::STORE.clear;@user=make_user;@lead=make_lead(@user,created_at:28.hours.ago) }
  teardown { restore_agent_fake;Copilot::Conversation::STORE.clear }
  def ask(extra={},headers:{},**options)
    post '/copilot/messages',params:{message:'Which leads are late?',page_path:'/',conversation_id:nil}.merge(extra).merge(options).to_json,headers:{'CONTENT_TYPE'=>'application/json'}.merge(headers)
  end
  test "team counts follow the existing salesperson roster policy without exposing identities or writes" do
    salesperson=make_user(organization:@user.organization,role:'salesperson')
    make_user
    login(salesperson)
    get settings_path
    assert_response :success
    assert_select 'h2',text:'Workspace team'
    assert_select 'form[action=?]',team_members_path,count:0
    @copilot_plan=copilot_plan(intent:'read_crm_data',query:'team_summary')
    before=[User.count,AuditEvent.count,Lead.count,Task.count,Activity.count]
    ask(message:'How many users are they in the team?')
    assert_response :success
    assert_equal 2,response.parsed_body['total']
    assert_equal({'manager'=>1,'salesperson'=>1},response.parsed_body['counts'])
    assert_not response.body.include?(@user.email)
    assert_equal before,[User.count,AuditEvent.count,Lead.count,Task.count,Activity.count]
  end
  test "real logout purges private server conversation and its pending plan" do
    login(@user)
    @copilot_plan=copilot_plan(intent:'page_action',destination:'analytics',action_task:'Open analytics')
    ask
    id=response.parsed_body['conversation_id']
    login_id=Session.where(user:@user).order(:id).last.id
    assert Copilot::Conversation.new(@user,login_id,id).history.any?
    delete logout_path
    assert_redirected_to login_path
    assert_not Session.exists?(login_id)
    assert_raises(PageAgent::Error){Copilot::Conversation.new(@user,login_id,id)}
  end
  test "login mandatory password and workspace checks prevent any provider request" do
    ask
    assert_redirected_to login_path
    assert_empty @copilot_requests
    @user.update!(password_change_required:true)
    post login_path,params:{email:@user.email,password:'test-password-123'}
    assert_redirected_to edit_password_path
    ask
    assert_redirected_to edit_password_path
    @user.update!(password_change_required:false)
    foreign=make_lead(make_user)
    ask(page_path:lead_path(foreign))
    assert_response :not_found
    ask(page_path:'/settings/password')
    assert_response :unprocessable_entity
    assert_empty @copilot_requests
  end
  test "verified factual response is scoped bounded secret free and changes no CRM table" do
    login(@user)
    @copilot_plan=copilot_plan(intent:'read_crm_data',query:'overdue_leads',audience:'mine',answer:'Fabricated 500 leads')
    models=[User,Session,Lead,Opportunity,Task,Activity,AuditEvent,Contact,Company,Organization]
    before=models.to_h{|model|[model.name,model.order(:id).map(&:attributes)]}
    ask
    assert_response :success
    json=response.parsed_body
    assert_equal 'verified_crm',json['kind']
    assert_equal 1,json['count']
    assert_equal lead_path(@lead),json['records'].first['path']
    assert_not response.body.include?('Fabricated')
    assert_not response.body.include?(@agent_key)
    assert_equal 'no-store',response.headers['Cache-Control']
    assert_equal before,models.to_h{|model|[model.name,model.order(:id).map(&:attributes)]}
  end
  test "CSRF arbitrary provider options malformed bodies unsupported methods and oversized input are rejected" do
    login(@user)
    previous=Copilot::MessagesController.allow_forgery_protection
    previous_dashboard=DashboardController.allow_forgery_protection
    Copilot::MessagesController.allow_forgery_protection=true
    DashboardController.allow_forgery_protection=true
    ask
    assert_response :unprocessable_entity
    assert_empty @copilot_requests
    get root_path
    token=Nokogiri::HTML(response.body).at_css('meta[name=csrf-token]')['content']
    headers={'X-CSRF-Token'=>token}
    ask({message:'Tell me how can I use the system?'},headers:headers)
    assert_response :success
    ask({target_url:'https://evil.test',apiKey:'never-forward'},headers:headers)
    assert_response :unprocessable_entity
    ask({message:'x'*601},headers:headers)
    assert_response :unprocessable_entity
    post '/copilot/messages',params:'not json',headers:{'CONTENT_TYPE'=>'application/json'}.merge(headers)
    assert_response :unprocessable_entity
    get '/copilot/messages'
    assert_response :not_found
    filtered=ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(message:'private',conversation_id:'private',page_query:'private')
    assert_equal ['[FILTERED]']*3,filtered.values
  ensure
    Copilot::MessagesController.allow_forgery_protection=previous
    DashboardController.allow_forgery_protection=previous_dashboard
  end
  test "malformed model timeouts and quota return recoverable safe feedback" do
    login(@user)
    @copilot_raw='PRIVATE_PROVIDER_RESPONSE'
    ask
    assert_response :bad_gateway
    assert_not response.body.include?('PRIVATE_PROVIDER_RESPONSE')
    @copilot_raw=nil;@agent_exception=Net::ReadTimeout.new
    ask
    assert_response :gateway_timeout
    @agent_exception=nil;@copilot_status=429
    ask
    assert_response :too_many_requests
    assert_equal '60',response.headers['Retry-After']
  end
  test "conversation cannot be reused by another login or workspace and outcome rechecks permission" do
    login(@user)
    @copilot_plan=copilot_plan(intent:'page_action',destination:'record',search:'Atlas Industries',action_task:'Open Atlas Industries')
    ask
    result=response.parsed_body
    foreign=make_lead(make_user)
    post '/copilot/outcome',params:{conversation_id:result['conversation_id'],run_id:result.dig('action','run_id'),page_path:lead_path(foreign),page_query:'',note_present:false,agent_success:true,execution_error:false}.to_json,headers:{'CONTENT_TYPE'=>'application/json'}
    assert_response :not_found
    login(make_user)
    ask(conversation_id:result['conversation_id'])
    assert_response :conflict
    assert_equal 'conversation_expired',response.parsed_body.dig('error','code')
  end
  test "contextual agent cannot finish before applied filters match its server held plan" do
    login(@user)
    @copilot_plan=copilot_plan(intent:'read_crm_data',query:'overdue_leads',audience:'mine',navigate:true,destination:'leads')
    ask
    result=response.parsed_body
    context={conversation_id:result['conversation_id'],run_id:result.dig('action','run_id'),page_path:'/',page_query:'',note_present:false,agent_request:agent_body}
    post '/agent/chat/completions',params:context.to_json,headers:{'CONTENT_TYPE'=>'application/json'}
    assert_response :bad_gateway # Fixture tried done, which is not an offered capability yet.
    alternatives=@agent_requests.last.dig('tools',0,'function','parameters','properties','action','anyOf')
    assert_not alternatives.any?{|item|item['properties'].key?('done')}
    context[:page_path]='/leads';context[:page_query]="?owner_id=#{@user.id}&attention=overdue"
    post '/agent/chat/completions',params:context.to_json,headers:{'CONTENT_TYPE'=>'application/json'}
    assert_response :success
    alternatives=@agent_requests.last.dig('tools',0,'function','parameters','properties','action','anyOf')
    assert alternatives.any?{|item|item['properties'].key?('done')}
    assert_equal ['done'],alternatives.flat_map{|item|item['properties'].keys}
    assert_not @agent_requests.last['messages'].first['content'].include?('fill_field')
    assert_includes @agent_requests.last['messages'].first['content'],'Rails has verified'
    @agent_action={'click_control'=>{'target'=>'control_1'}}
    post '/agent/chat/completions',params:context.to_json,headers:{'CONTENT_TYPE'=>'application/json'}
    assert_response :bad_gateway
  end
end
