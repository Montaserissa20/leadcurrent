require 'test_helper'
require_relative '../support/page_agent_test_support'

class CopilotDataTest < ActiveSupport::TestCase
  include PageAgentTestSupport
  setup { install_agent_fake; Copilot::Conversation::STORE.clear; @user=make_user }
  teardown { restore_agent_fake; Copilot::Conversation::STORE.clear }
  def read(query,**options)
    Copilot::CrmReader.new(@user,copilot_plan(query:query,**options)).call
  end

  test 'both roles read only registered organization counts including themselves without team identities' do
    salesperson=make_user(organization:@user.organization,role:'salesperson')
    salesperson.update!(name:'PRIVATE_TEAM_CANARY')
    make_user(organization:@user.organization,role:'salesperson')
    foreign=make_user
    [@user,salesperson].each do |actor|
      result=Copilot::CrmReader.new(actor,copilot_plan(query:'team_summary',status:'salesperson',audience:'mine')).call
      assert_equal 3,result[:total]
      assert_equal 2,result[:count]
      assert_equal({'manager'=>1,'salesperson'=>2},result[:counts])
      assert result[:includes_current_user]
      assert_includes result[:answer],'including you'
      assert_includes result[:answer],'online status is unknown'
      assert_empty result[:records]
      assert_not result.to_json.include?(salesperson.name)
      assert_not result.to_json.include?(foreign.email)
    end
  end
  test 'zero role and zero registered membership are factual rather than an invented user' do
    assert_equal 0,read('team_summary',status:'salesperson')[:count]
    empty_org=Organization.create!(name:'Empty organization')
    stale_user=User.new(organization:empty_org,role:'salesperson')
    result=Copilot::CrmReader.new(stale_user,copilot_plan(query:'team_summary')).call
    assert_equal 0,result[:total]
    assert_equal 0,result[:count]
    assert_not result[:includes_current_user]
    assert_includes result[:answer],'not including you'
    # A real authenticated account is necessarily registered; zero is only a stale/internal edge case.
  end
  test 'paraphrased team requests reach a strict supported capability and retrieved data never goes to Groq' do
    make_user(organization:@user.organization,role:'salesperson').update!(name:'PRIVATE_TEAM_CANARY')
    # Model transport fixtures exercise the protocol; separate live checks exercise language.
    ['How many people work with me?',"What is the size of our sales team?",'Do we have more than three users?'].each do |question|
      @copilot_plan=copilot_plan(intent:'read_crm_data',query:'team_summary',answer:'999 fabricated people')
      result=Copilot::Assistant.new(@user,'test-login').call(message:question,page_path:'/')
      assert_equal 2,result[:count]
      assert_equal 'verified_crm',result[:kind]
      assert_not result[:answer].include?('999')
      assert_nil result[:action]
    end
    assert_not @copilot_requests.to_json.include?('PRIVATE_TEAM_CANARY')
    assert_empty @agent_requests
  end
  test 'follow-up descriptors retain team role and overdue subset without sending query results' do
    @copilot_plan=copilot_plan(intent:'read_crm_data',query:'team_summary')
    first=Copilot::Assistant.new(@user,'login').call(message:'How many users are in my team?',page_path:'/')
    @copilot_plan=copilot_plan(intent:'read_crm_data',query:'team_summary',status:'salesperson')
    reply=Copilot::Assistant.new(@user,'login',first[:conversation_id]).call(message:'How many are salespeople?',page_path:'/')
    assert_equal 0,reply[:count]
    history=JSON.parse(@copilot_requests.last['messages'].last['content'])['history']
    assert_equal 'team_summary',history.last.dig('previous','query')
    assert_not history.to_json.include?('registered users')
    assert_not history.to_json.include?('counts')
    @copilot_plan=copilot_plan(intent:'read_crm_data',query:'overdue_leads',audience:'mine',search:'Atlas')
    Copilot::Assistant.new(@user,'login',first[:conversation_id]).call(message:'Which of my Atlas leads are late?',page_path:'/')
    @copilot_plan=copilot_plan(intent:'read_crm_data',query:'overdue_leads',audience:'mine',search:'Atlas')
    Copilot::Assistant.new(@user,'login',first[:conversation_id]).call(message:'Which one first?',page_path:'/')
    last=JSON.parse(@copilot_requests.last['messages'].last['content'])['history'].last['previous']
    assert_equal({'query'=>'overdue_leads','audience'=>'mine','search'=>'Atlas'},last.slice('query','audience','search'))
  end
  test 'lead totals stages assigned lists and uncontacted records are authoritative and scoped' do
    lead=make_lead(@user,created_at:26.hours.ago)
    qualified=qualify(make_lead(@user))
    colleague=make_user(organization:@user.organization)
    make_lead(colleague)
    make_lead(make_user)
    assert_equal 3,read('lead_status')[:count]
    assert_equal 1,read('lead_status',status:'qualified')[:count]
    assert_equal 2,read('leads',audience:'mine')[:count]
    assert_equal ["/leads/#{lead.id}"],read('uncontacted_leads',audience:'mine')[:records].map{|r|r[:path]}
    assert_equal 0,read('leads',status:'disqualified')[:count]
    assert qualified.reload.first_contact_at
  end
  test 'most urgent overdue follow-up stays in the requested subset and uses official priorities' do
    oldest=make_lead(@user,created_at:30.hours.ago)
    later=make_lead(@user,created_at:26.hours.ago)
    foreign=make_lead(make_user,created_at:80.hours.ago)
    result=read('overdue_leads',audience:'mine')
    assert_equal ["/leads/#{oldest.id}","/leads/#{later.id}"],result[:records].map{|r|r[:path]}
    expected=NextBestAction.new(@user).call(record:oldest,limit:1).first
    assert_equal expected.priority,result[:records].first[:priority]
    assert_equal 100,expected.priority
    assert_equal "/leads/#{oldest.id}",result[:recommendation][:path]
    assert_not result[:records].any?{|r|r[:path]=="/leads/#{foreign.id}"}
    assert_equal 0,read('overdue_leads',search:'No matches')[:count]
  end
  test 'opportunity summaries keep stages and currencies separate and use the exact inactivity boundary' do
    travel_to Time.zone.local(2026,10,21,12)
    usd=make_opportunity(@user)
    eur=make_opportunity(@user);eur.update!(currency:'EUR',value:90,last_activity_at:Time.current-NextBestAction::INACTIVITY_WINDOW)
    usd.update!(last_activity_at:Time.current-NextBestAction::INACTIVITY_WINDOW+1.second)
    OpportunityTransition.call(usd,actor:@user,to:'proposal')
    OpportunityTransition.call(usd,actor:@user,to:'negotiation')
    make_opportunity(make_user)
    result=read('opportunity_summary')
    assert_equal 2,result[:count]
    assert_equal({'qualification'=>1,'negotiation'=>1},result[:counts])
    assert_equal({'USD'=>'12000.0','EUR'=>'90.0'},result[:pipeline_values])
    assert_equal ["/opportunities/#{eur.id}"],read('inactive_opportunities')[:records].map{|r|r[:path]}
    OpportunityTransition.call(usd,actor:@user,to:'won')
    assert_equal 1,read('opportunities',status:'won')[:count]
    assert_equal({'EUR'=>'90.0'},read('opportunity_summary')[:pipeline_values])
  end
  test 'task today and overdue use user timezone and exclude completed future and foreign tasks' do
    @user.update!(time_zone:'Pacific Time (US & Canada)')
    travel_to Time.utc(2026,10,22,1)
    lead=make_lead(@user)
    today=Task.create!(organization:@user.organization,owner:@user,lead:lead,title:'Local today',due_at:Time.utc(2026,10,21,20))
    Task.create!(organization:@user.organization,owner:@user,lead:lead,title:'Local tomorrow',due_at:Time.utc(2026,10,22,8))
    Task.create!(organization:@user.organization,owner:@user,lead:lead,title:'Completed',due_at:1.hour.ago,completed_at:Time.current)
    foreign=make_user;foreign_lead=make_lead(foreign)
    Task.create!(organization:foreign.organization,owner:foreign,lead:foreign_lead,title:'Foreign',due_at:1.hour.ago)
    assert_equal 1,read('pending_tasks',period:'today',audience:'mine')[:count]
    assert_equal today.title,read('pending_tasks',period:'overdue',audience:'mine')[:records].first[:title]
    assert_nil lead.reload.first_contact_at
  end
  test 'named customer status is bounded and excludes another workspace even for the same company name' do
    lead=make_lead(@user);deal=convert(qualify(lead))
    foreign=make_lead(make_user)
    result=read('customer_summary',search:'Atlas Industries')
    assert_equal 2,result[:count]
    assert_equal ["/leads/#{lead.id}","/opportunities/#{deal.id}"],result[:records].map{|r|r[:path]}
    assert_not result.to_json.include?(foreign.owner.email)
    assert_equal 0,read('customer_summary',search:'%')[:count]
  end
  test 'query-specific argument validation rejects unsupported fields and incompatible filters' do
    [copilot_plan(intent:'read_crm_data',query:'team_summary',status:'won'),copilot_plan(intent:'read_crm_data',query:'leads',status:'manager'),copilot_plan(intent:'read_crm_data',query:'customer_summary'),copilot_plan(intent:'read_crm_data',query:'inactive_opportunities',period:'today'),copilot_plan(intent:'read_crm_data',query:'team_summary',search:'password_digest'),copilot_plan(intent:'read_crm_data',query:'User')].each do |bad|
      assert_raises(PageAgent::Error){Copilot::Planner.validate!(bad)}
    end
    assert_raises(PageAgent::Error){Copilot::Planner.validate!(copilot_plan.merge('columns'=>['password_digest']))}
    assert_raises(PageAgent::Error){Copilot::Planner.validate!(copilot_plan.merge('navigate'=>true))}
    plan=copilot_plan(intent:'read_crm_data',query:'overdue_leads',period:'overdue')
    assert_equal 'all',Copilot::Planner.validate!(plan)['period']
    assert_raises(PageAgent::Error){Copilot::Planner.validate!(copilot_plan(intent:'read_crm_data',query:'overdue_leads',period:'today'))}
  end
  test 'logout purge deletes only the matching user login conversation including pending actions' do
    current=Copilot::Conversation.new(@user,'login-a');current.remember('Private question',copilot_plan)
    current.pending(copilot_plan(intent:'page_action',destination:'analytics',action_task:'Open analytics'))
    other=Copilot::Conversation.new(@user,'login-b');other.remember('Other question',copilot_plan)
    Copilot::Conversation.clear_session(@user,'login-a')
    assert_equal :conversation_expired,assert_raises(PageAgent::Error){Copilot::Conversation.new(@user,'login-a',current.id)}.code
    assert_equal 'Other question',Copilot::Conversation.new(@user,'login-b',other.id).history.first[:question]
  end
  test 'record opening uses scoped type hints without routes and clarifies ambiguous or missing customers' do
    lead=make_lead(@user)
    foreign=make_lead(make_user)
    @copilot_plan=copilot_plan(intent:'page_action',destination:'record',search:'Atlas Industries',action_task:'Open Atlas Industries')
    reply=Copilot::Assistant.new(@user,'login').call(message:'Open Atlas Industries',page_path:'/opportunities')
    assert_includes reply[:action][:task],'Open the Leads list FIRST'
    assert_not reply[:action][:task].include?("/leads/#{lead.id}")
    assert_not reply[:action][:task].include?(foreign.contact.email)
    assert_equal 1,reply[:count]
    make_lead(@user)
    reply=Copilot::Assistant.new(@user,'login').call(message:'Open Atlas Industries',page_path:'/opportunities')
    assert_equal 'clarification',reply[:kind]
    assert_nil reply[:action]
    @copilot_plan['search']='No such company'
    reply=Copilot::Assistant.new(@user,'login').call(message:'Open No such company',page_path:'/opportunities')
    assert_equal 0,reply[:count]
    assert_nil reply[:action]
  end
  test 'provider JSON generation rejection stays recoverable and never logs failed private output' do
    @copilot_status=400
    @copilot_raw=JSON.generate(error:{code:'json_validate_failed',message:'PRIVATE_PROVIDER_CANARY',failed_generation:@agent_key})
    events=[]
    subscription=ActiveSupport::Notifications.subscribe('failure.page_agent'){|_name,_start,_finish,_id,payload|events<<payload}
    error=assert_raises(PageAgent::Error){Copilot::Assistant.new(@user,'login').call(message:'How can I use the system?',page_path:'/')}
    assert_equal :invalid_response,error.code
    assert_not error.message.include?('PRIVATE_PROVIDER_CANARY')
    assert_not events.to_json.include?(@agent_key)
    assert_not events.to_json.include?('PRIVATE_PROVIDER_CANARY')
    assert_equal 'json_validate_failed',events.last[:code]
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription) if subscription
  end
end
