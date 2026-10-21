require "test_helper"
require_relative "../support/page_agent_test_support"

class CopilotTest < ActiveSupport::TestCase
  include PageAgentTestSupport
  setup { install_agent_fake; Copilot::Conversation::STORE.clear; @user=make_user(role:'salesperson') }
  teardown { restore_agent_fake; Copilot::Conversation::STORE.clear }
  def ask(message='Which leads are late?',**options)
    Copilot::Assistant.new(@user,'session-a',options[:conversation_id]).call(message:message,page_path:options[:page_path]||'/')
  end
  test "structured model routing supplies natural help and follow-up context without tools or customer history" do
    lead=make_lead(@user);lead.update!(notes:'PRIVATE_CUSTOMER_CANARY')
    @copilot_plan=copilot_plan(answer:'An opportunity is a qualified potential deal. Track it through Proposal, Negotiation and Won or Lost.')
    first=ask('Explain what an opportunity is')
    assert_equal 'guide',first[:kind]
    assert_includes first[:answer],'qualified potential deal'
    @copilot_plan=copilot_plan(answer:'Use the next permitted stage on the customer page after reviewing the recorded contact.')
    ask('How do I move it forward?',conversation_id:first[:conversation_id])
    sent=@copilot_requests.last
    assert_equal 'none',sent['tool_choice']
    assert_equal true,sent.dig('response_format','json_schema','strict')
    assert_equal 'openai/gpt-oss-20b',sent['model']
    assert_equal 600,sent['max_completion_tokens']
    assert_equal 0,sent['temperature']
    assert_includes sent['messages'].last['content'],'Explain what an opportunity is'
    assert_not @copilot_requests.to_json.include?('PRIVATE_CUSTOMER_CANARY')
    assert_empty @agent_requests
  end
  test "overdue facts and empty results come from scoped records even when model invents data" do
    own=make_lead(@user,created_at:26.hours.ago)
    colleague=make_user(organization:@user.organization);other=make_lead(colleague,created_at:28.hours.ago)
    foreign=make_lead(make_user,created_at:30.hours.ago)
    @copilot_plan=copilot_plan(intent:'read_crm_data',query:'overdue_leads',audience:'mine',answer:'There are 999 leads at Fabricated Inc.')
    result=ask
    assert_equal 1,result[:count]
    assert_equal ["/leads/#{own.id}"],result[:records].map{|r|r[:path]}
    assert_includes result[:records].first[:deadline],@user.time_zone=='Europe/Istanbul' ? '+03' : ''
    assert_not result.to_json.include?('999')
    assert_not result.to_json.include?('Fabricated')
    assert_not result.to_json.include?(foreign.contact.email)
    @copilot_plan['audience']='workspace'
    assert_equal 2,ask[:count]
    assert_equal ["/leads/#{other.id}","/leads/#{own.id}"],ask[:records].map{|r|r[:path]}
    @copilot_plan['search']='No matching company'
    empty=ask
    assert_equal 0,empty[:count]
    assert_includes empty[:answer],'no overdue leads'
    assert_empty empty[:records]
  end
  test "bounded data capabilities cover attention status opportunities tasks and authoritative NBA without writes" do
    travel_to Time.zone.local(2026,10,20,12)
    lead=make_lead(@user,created_at:27.hours.ago)
    task=ScheduleFollowUp.call(lead,actor:@user,title:'Call for review',due_at:1.hour.from_now)
    deal=make_opportunity(@user)
    OpportunityTransition.call(deal,to:'proposal',actor:@user)
    OpportunityTransition.call(deal,to:'negotiation',actor:@user)
    before=[lead.reload.attributes,deal.reload.attributes,Activity.count,Task.count,AuditEvent.count]
    @copilot_plan=copilot_plan(intent:'read_crm_data',query:'attention_leads',audience:'mine')
    assert_equal 1,ask[:count]
    @copilot_plan['query']='pending_tasks';@copilot_plan['period']='today'
    result=ask
    assert_equal 1,result[:count]
    assert_equal task.title,result[:records].first[:title]
    @copilot_plan['query']='opportunities';@copilot_plan['status']='negotiation';@copilot_plan['period']='all'
    assert_equal ["/opportunities/#{deal.id}"],ask[:records].map{|r|r[:path]}
    @copilot_plan['query']='lead_status';@copilot_plan['status']='any'
    assert_includes ask[:answer],'2 leads'
    @copilot_plan['query']='next_best_action'
    nba=ask
    assert_includes nba[:records].first[:detail],'Priority 100'
    assert_equal before,[lead.reload.attributes,deal.reload.attributes,Activity.count,Task.count,AuditEvent.count]
  end
  test "read-only lists are bounded and wildcard searches do not expand permission scopes" do
    12.times { make_lead(@user,created_at:28.hours.ago) }
    @copilot_plan=copilot_plan(intent:'read_crm_data',query:'overdue_leads',audience:'mine')
    result=ask
    assert_equal 12,result[:count]
    assert_equal 10,result[:records].size
    assert_includes result[:answer],'first 10'
    @copilot_plan['search']='%'
    assert_equal 0,ask[:count]
    @copilot_plan['intent']='show_crm_data'
    assert_nil ask[:action]
    assert_empty @agent_requests
  end
  test "outcomes check actual authorized page and filters instead of trusting done and prevent replay" do
    lead=make_lead(@user,created_at:28.hours.ago)
    @copilot_plan=copilot_plan(intent:'read_crm_data',query:'overdue_leads',audience:'mine',navigate:true,destination:'leads',action_task:'Show my late leads')
    reply=ask('Show my late leads')
    assistant=Copilot::Assistant.new(@user,'session-a',reply[:conversation_id])
    input={'run_id'=>reply[:action][:run_id],'page_path'=>'/leads','page_query'=>'?attention=overdue','agent_success'=>true,'note_present'=>false}
    result=assistant.finish(input)
    assert_equal false,result[:verified]
    assert_equal 1,result[:count]
    assert_includes result[:answer],'couldn’t verify'
    assert_raises(PageAgent::Error){assistant.finish(input)}
    reply=ask('Show my late leads')
    input['run_id']=reply[:action][:run_id];input['page_query']="?attention=overdue&owner_id=#{@user.id}"
    result=Copilot::Assistant.new(@user,'session-a',reply[:conversation_id]).finish(input)
    assert result[:verified]
    assert_equal "/leads/#{lead.id}",result[:records].first[:path]
  end
  test "conversation and pending actions are bound to workspace user login session and expiry" do
    response=ask('How do I use the system?')
    id=response[:conversation_id]
    assert_raises(PageAgent::Error){Copilot::Assistant.new(make_user,'session-a',id)}
    assert_raises(PageAgent::Error){Copilot::Assistant.new(@user,'another-login',id)}
    travel_to 11.minutes.from_now do
      assert_equal :conversation_expired,assert_raises(PageAgent::Error){Copilot::Assistant.new(@user,'session-a',id)}.code
    end
  end
  test "actual authorized record outcome can succeed when done is false but execution errors stay blocked" do
    lead=make_lead(@user)
    plan=copilot_plan(intent:'page_action',destination:'record',search:'Atlas Industries',action_task:'Open Atlas Industries')
    input={'page_path'=>"/leads/#{lead.id}",'page_query'=>'','agent_success'=>false,'note_present'=>false,'execution_error'=>false}
    assert Copilot::Outcome.verified?(@user,plan,input)
    input['execution_error']=true
    assert_not Copilot::Outcome.verified?(@user,plan,input)
    input['execution_error']=false;plan['search']='Different company'
    assert_not Copilot::Outcome.verified?(@user,plan,input)
  end
  test "router rejects SQL arbitrary model IDs oversized or malformed model output safely" do
    [copilot_plan.merge('sql'=>'SELECT * FROM users'),copilot_plan(intent:'execute_javascript'),copilot_plan(answer:'x'*1501),copilot_plan(intent:'page_action',destination:'record',action_task:'Open anything'),copilot_plan(intent:'read_crm_data',query:'none')].each do |bad|
      @copilot_plan=bad
      assert_equal :invalid_response,assert_raises(PageAgent::Error){ask}.code
    end
    @copilot_raw='private garbage'
    error=assert_raises(PageAgent::Error){ask}
    assert_not error.message.include?('private garbage')
  end
  test "provider token headers and 429 cooldown bound adaptive pacing without storing content" do
    response=Struct.new(:code,:headers){def [](key)=headers[key]}.new('200',{'x-ratelimit-remaining-tokens'=>'20','x-ratelimit-reset-tokens'=>'2.5s'})
    PageAgent::Pacing.observe(response)
    error=assert_raises(PageAgent::Error){PageAgent::Pacing.reserve!(messages:[{content:'safe'}],max_completion_tokens:800)}
    assert_equal 3,error.retry_after
    travel_to 4.seconds.from_now do
      assert_nil PageAgent::Pacing.reserve!(messages:[{content:'safe'}],max_completion_tokens:800)
    end
    response.code='429';response.headers={'retry-after'=>'9'}
    PageAgent::Pacing.observe(response)
    assert_equal 9,PageAgent::Pacing.retry_after
    assert_raises(PageAgent::Error){PageAgent::Pacing.reserve!(messages:[],max_completion_tokens:1)}
  end
  test "database query failure cannot become a claimed empty or successful CRM result" do
    relation=Object.new
    def relation.group(*) = raise(ActiveRecord::StatementInvalid.new('private database diagnostic'))
    reader=Copilot::CrmReader.new(@user,copilot_plan(query:'lead_status'))
    reader.define_singleton_method(:scope) { |_model| relation }
    error=assert_raises(PageAgent::Error) { reader.call }
    assert_equal :unverified,error.code
    assert_not error.message.include?('private database diagnostic')
  end
  test "a corrupt cross workspace company association cannot leak through verified rows" do
    foreign=make_lead(make_user)
    lead=make_lead(@user,created_at:28.hours.ago)
    lead.update_column(:company_id,foreign.company_id)
    plan=copilot_plan(intent:'read_crm_data',query:'overdue_leads',audience:'mine')
    assert_equal :unverified,assert_raises(PageAgent::Error){Copilot::CrmReader.new(@user,plan).call}.code
  end
  test "batched filter protocol bounds every target text and count while redacting secrets" do
    valid={'action'=>{'apply_filters'=>{'target'=>'control_1','fields'=>[{'target'=>'control_2','text'=>"#{@agent_key} person@example.test"}]}}}
    clean=PageAgent::Protocol.arguments!(valid)
    assert_not clean.to_json.include?(@agent_key)
    assert_not clean.to_json.include?('person@example.test')
    [[],Array.new(5){|i|{'target'=>"control_#{i+2}",'text'=>'Me'}},[{'target'=>'https://evil.test','text'=>'x'}],[{'target'=>'control_2','text'=>'x'*601}],[{'target'=>'control_2','text'=>'x'},{'target'=>'control_2','text'=>'y'}]].each do |fields|
      assert_raises(PageAgent::Error){PageAgent::Protocol.arguments!({'action'=>{'apply_filters'=>{'target'=>'control_1','fields'=>fields}}})}
    end
  end
  test "notes on readable colleague or closed records get a natural permission explanation without browser actions" do
    colleague=make_user(organization:@user.organization)
    lead=make_lead(colleague)
    @copilot_plan=copilot_plan(intent:'page_action',destination:'note',action_task:'Prepare an unsaved follow-up note')
    response=ask('Prepare a follow-up note',page_path:"/leads/#{lead.id}")
    assert_equal 'safety',response[:kind]
    assert_includes response[:answer],'only its owner'
    lead=make_lead(@user);qualify(lead);convert(lead)
    response=ask('Prepare a follow-up note',page_path:"/leads/#{lead.id}")
    assert_equal 'safety',response[:kind]
    assert_includes response[:answer],'closed'
    assert_empty @agent_requests
  end
end
