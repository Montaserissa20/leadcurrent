require 'application_system_test_case'
require_relative '../support/page_agent_test_support'

class CopilotBrowserTest < ApplicationSystemTestCase
  include PageAgentTestSupport
  setup do
    install_agent_fake;Copilot::Conversation::STORE.clear
    @user=make_user(role:'salesperson');@lead=make_lead(@user,created_at:28.hours.ago)
    @lead.update!(title:'Atlas renewal',notes:'PRIVATE_HISTORY_CANARY')
    @previous_wait=Capybara.default_max_wait_time;Capybara.default_max_wait_time=12
    page.driver.browser.execute_cdp('Emulation.clearDeviceMetricsOverride')
    @probe=page.driver.browser.execute_cdp('Page.addScriptToEvaluateOnNewDocument',source:"window.copilotCsp=0;document.addEventListener('securitypolicyviolation',()=>window.copilotCsp++)")['identifier']
    page.current_window.resize_to(1440,1050)
    visit login_path;fill_in 'Email address',with:@user.email;fill_in 'Password',with:'test-password-123';click_button 'Sign in →'
    assert_text 'Make your next move count.'
    click_button 'AI Agent'
  end
  teardown do
    Capybara.default_max_wait_time=@previous_wait
    page.driver.browser.execute_cdp('Page.removeScriptToEvaluateOnNewDocument',identifier:@probe) if @probe
    restore_agent_fake;Copilot::Conversation::STORE.clear
  end
  def chat(question,plan)
    @copilot_plan=plan
    within('#agent-panel'){fill_in 'What would you like to do?',with:question;click_button 'Run'}
    assert_selector '#leadcurrent-agent[data-status=completed]'
    assert_equal 0,page.evaluate_script('window.copilotCsp')
  end
  test "ordinary help and short follow-up stay conversational without tools and errors preserve the chat" do
    chat('Tell me how can I use the system?',copilot_plan(answer:'LeadCurrent helps you track leads, qualify them into opportunities, and manage follow-up tasks. You can start with New lead.'))
    assert_selector '.copilot-message[data-role=user]',text:'Tell me how can I use the system?'
    assert_selector '.copilot-message[data-role=assistant]',text:'follow-up tasks'
    chat('Explain what an opportunity is',copilot_plan(answer:'An opportunity is a qualified potential sale. Review it through Proposal and Negotiation, then record Won or Lost manually.'))
    assert_text 'qualified potential sale'
    assert_includes @copilot_requests.last['messages'].last['content'],'Tell me how can I use the system?'
    assert_empty @agent_requests
    assert_no_selector '.agent-activity[open]'
    @copilot_raw='invalid provider body'
    within('#agent-panel'){click_button 'Run'}
    assert_selector '#leadcurrent-agent[data-status=failed]'
    assert_text 'qualified potential sale'
    assert_not page.text.include?('invalid provider body')
    @copilot_raw=nil
    chat('And what is the next step?',copilot_plan(answer:'Review the customer and choose the permitted next stage manually.'))
    assert_text 'choose the permitted next stage manually'
  end
  test "show overdue leads uses official DOM filtering and reports actual matching rows with collapsed friendly activity" do
    colleague=make_user(organization:@user.organization)
    make_lead(colleague,created_at:30.hours.ago).update!(title:'Colleague confidential-to-query')
    @agent_steps=[['click_control','link: Leads'],['apply_filters','filter: Filter',[['select: Owner','Me'],['select: First contact','Overdue']]],['done','I found 999 fake leads.']]
    chat('Show me overdue leads',copilot_plan(intent:'read_crm_data',query:'overdue_leads',audience:'mine',navigate:true,destination:'leads',action_task:'Show my overdue leads.'))
    assert_current_path leads_path,ignore_query:true
    assert_selector '.copilot-message',text:'I found 1 overdue lead for your records.'
    within('.copilot-conversation') do
      assert_link 'Atlas renewal',href:lead_path(@lead)
      assert_text @lead.first_contact_deadline.in_time_zone(@user.time_zone).strftime('%d %b %Y %H:%M')
      assert_no_text 'Colleague confidential-to-query'
      assert_no_text '999 fake leads'
      assert_no_text 'click_control'
    end
    assert_no_selector '.agent-activity[open]'
    find('.agent-activity summary').click
    assert_text 'Applied the selected filters.'
    assert_equal 0,@lead.activities.count
    assert_nil @lead.reload.first_contact_at
    assert_not @copilot_requests.to_json.include?('PRIVATE_HISTORY_CANARY')
    assert_equal 3,@agent_requests.size
  end
  test "late paraphrase and empty query get verified answers without pretending the page was filtered" do
    chat('Which leads are late?',copilot_plan(intent:'read_crm_data',query:'overdue_leads',audience:'mine',answer:'Fake 500 records'))
    assert_selector '.copilot-message',text:'I found 1 overdue lead'
    assert_empty @agent_requests
    chat('What about a nonexistent company?',copilot_plan(intent:'read_crm_data',query:'overdue_leads',audience:'mine',search:'No matching company'))
    assert_selector '.copilot-message',text:'I found no overdue leads'
    assert_current_path root_path
    assert_equal 'new',@lead.reload.status
  end
  test "Atlas search and analytics use real Page Agent actions with verified outcomes" do
    visit opportunities_path(status:'negotiation');click_button 'AI Agent'
    @agent_steps=[['click_control','link: Leads'],['fill_field','search: Search','Atlas Industries'],['click_control','filter: Filter'],['click_control','link: Open Atlas renewal at Atlas Industries'],['done','Opened.']]
    chat('Find Atlas Industries',copilot_plan(intent:'page_action',destination:'record',search:'Atlas Industries',action_task:'Find and open Atlas Industries.'))
    assert_current_path lead_path(@lead)
    assert_selector '.copilot-message',text:'Opened Atlas renewal at Atlas Industries.'
    assert_includes @agent_requests.first['messages'].last['content'],'Open the Leads list FIRST'
    # Independent navigation case starts with a fresh synthetic quota; limits/backoff are tested separately.
    PageAgent::RequestGate::STORE.clear
    @agent_steps=[['click_control','link: Analytics'],['done','Analytics open']]
    chat('Go to analytics',copilot_plan(intent:'page_action',destination:'analytics',action_task:'Go to analytics.'))
    assert_current_path analytics_path
    assert_selector '.copilot-message',text:'Opened Analytics.'
    assert_selector '#leadcurrent-agent',count:1
    page.go_back;assert_selector '#leadcurrent-agent',count:1
    page.go_forward;assert_selector '#leadcurrent-agent',count:1
    count=@copilot_requests.size;page.refresh
    assert_no_selector '#leadcurrent-agent[data-status=thinking]'
    assert_equal count,@copilot_requests.size
  end
  test "unsaved note remains unsubmitted and premature done is not accepted as navigation success" do
    visit lead_path(@lead);click_button 'AI Agent'
    @agent_steps=[['fill_field','note: Prepare an unsaved follow-up note','Please review the subscription requirements.'],['done','Saved the contact.']]
    chat('Prepare a follow-up note',copilot_plan(intent:'page_action',destination:'note',action_task:'Prepare an unsaved follow-up note.'))
    assert_text 'An unsaved note is present'
    assert_equal 'note',page.find('select[name=action_kind]').value
    assert_equal 0,@lead.activities.count
    assert_equal 0,@lead.tasks.count
    assert_nil @lead.reload.first_contact_at
    @agent_steps=[['done','Analytics is open.']]
    @copilot_plan=copilot_plan(intent:'page_action',destination:'analytics',action_task:'Go to analytics.')
    within('#agent-panel'){fill_in 'What would you like to do?',with:'Go to analytics';click_button 'Run'}
    assert_selector '#leadcurrent-agent[data-status=failed]'
    assert_text 'couldn’t verify the requested page action'
    assert_current_path lead_path(@lead)
  end
  test "forbidden actions clarify unknown requests and password help require no agent execution" do
    before=[@lead.reload.attributes,User.count,Task.count,Activity.count,AuditEvent.count]
    chat('Mark this deal won',copilot_plan(intent:'unsupported_action',answer:'I cannot change a deal status automatically. Open the opportunity and review the permitted next stage yourself; only Negotiation can move to Won.'))
    assert_text 'cannot change a deal status automatically'
    chat('Do the thing with it',copilot_plan(intent:'clarify',answer:'Which customer or page do you mean, and what would you like to do?'))
    assert_text 'Which customer or page'
    chat('Where can I change my password?',copilot_plan(answer:'Use Settings & team, then Security & Password. Enter your current password there, never in chat.',help_link:'password'))
    assert_link 'Security & Password',href:edit_password_path
    assert_current_path root_path
    assert_empty @agent_requests
    assert_equal before,[@lead.reload.attributes,User.count,Task.count,Activity.count,AuditEvent.count]
    page.current_window.resize_to(390,844)
    page.driver.browser.execute_cdp('Emulation.setDeviceMetricsOverride',width:390,height:844,deviceScaleFactor:1,mobile:true)
    %w[light dark].each do |theme|
      page.execute_script('document.documentElement.dataset.theme=arguments[0]',theme)
      assert page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')
      assert find_field('What would you like to do?').visible?
    end
  end
  test "provider 429 retries once after its bounded wait and Stop cancels a further wait" do
    @copilot_statuses=[429,200];@copilot_retry_after=1
    chat('How can I use LeadCurrent?',copilot_plan(answer:'Start by creating a lead and recording your customer contact.'))
    assert_equal 2,@copilot_requests.size
    assert_text 'Start by creating a lead'
    @copilot_statuses=[429,200];@copilot_retry_after=3
    within('#agent-panel'){fill_in 'What would you like to do?',with:'Explain opportunities';click_button 'Run'}
    assert_text 'Waiting 3 seconds'
    within('#agent-panel'){click_button 'Stop'}
    assert_selector '#leadcurrent-agent[data-status=stopped]'
    sleep 3.1
    assert_equal 3,@copilot_requests.size
    assert_text 'Start by creating a lead'
  end
  test "filter batches reject other GET forms and note fields without any submission" do
    visit leads_path;click_button 'AI Agent'
    page.execute_script("document.querySelector('#main-content').insertAdjacentHTML('beforeend','<form class=filters method=get action=/leads><label for=other-q>Other search</label><input type=search id=other-q name=q><input type=submit value=OtherFilter></form>');window.batchSubmits=0;document.querySelectorAll('form.filters').forEach(f=>f.addEventListener('submit',()=>window.batchSubmits++))")
    @copilot_plan=copilot_plan(intent:'page_action',destination:'analytics',action_task:'Filter the current list.')
    @agent_steps=[['apply_filters','filter: Filter',[['search: Other search','Unauthorized cross-form field']]]]
    within('#agent-panel'){fill_in 'What would you like to do?',with:'Apply filters';click_button 'Run'}
    assert_selector '#leadcurrent-agent[data-status=failed]'
    assert_equal 0,page.evaluate_script('window.batchSubmits')
    assert_equal '',find_field('Other search').value
    visit lead_path(@lead);click_button 'AI Agent'
    page.execute_script("document.querySelector('#main-content').insertAdjacentHTML('beforeend','<form class=filters method=get action=/leads><input type=search name=q><input type=submit value=OtherFilter></form>');window.batchSubmits=0;document.querySelector('form.filters').addEventListener('submit',()=>window.batchSubmits++)")
    @copilot_plan=copilot_plan(intent:'page_action',destination:'note',action_task:'Prepare an unsaved note.')
    @agent_steps=[['apply_filters','filter: OtherFilter',[['note: Prepare an unsaved follow-up note','Never write this body']]]]
    within('#agent-panel'){fill_in 'What would you like to do?',with:'Prepare note';click_button 'Run'}
    assert_selector '#leadcurrent-agent[data-status=failed]'
    assert_equal 0,page.evaluate_script('window.batchSubmits')
    assert_equal '',find_field('What happened?').value
    assert_equal 0,@lead.activities.count
    assert_equal 0,@lead.tasks.count
  end
  test "team answers and follow-ups remain readable with keyboard controls on mobile and desktop" do
    make_user(organization:@user.organization,role:'manager')
    chat('How many people work with me?',copilot_plan(intent:'read_crm_data',query:'team_summary'))
    assert_selector '.copilot-message',text:'2 registered users, including you: 1 manager and 1 salesperson'
    assert_empty @agent_requests
    @copilot_plan=copilot_plan(intent:'read_crm_data',query:'team_summary',status:'salesperson')
    fill_in 'What would you like to do?',with:'How many of them are salespeople?'
    find_field('What would you like to do?').send_keys([:control,:enter])
    assert_selector '#leadcurrent-agent[data-status=completed]'
    assert_selector '.copilot-message',text:'Registered salespeople: 1'
    assert_no_selector '.agent-activity[open]'
    assert_includes @copilot_requests.last['messages'].last['content'],'team_summary'
    page.current_window.resize_to(390,844)
    page.driver.browser.execute_cdp('Emulation.setDeviceMetricsOverride',width:390,height:844,deviceScaleFactor:1,mobile:true)
    %w[light dark].each do |theme|
      page.execute_script('document.documentElement.dataset.theme=arguments[0]',theme)
      assert page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')
      assert page.evaluate_script("(()=>{const r=document.querySelector('.copilot-composer').getBoundingClientRect();return r.top>=0&&r.bottom<=innerHeight})()")
      assert_selector '.copilot-message small',text:'Verified CRM data'
    end
    find_field('What would you like to do?').send_keys(:escape)
    assert_no_selector '#agent-panel'
    assert_equal 'false',find('.agent-launcher')['aria-expanded']
    assert_equal 'agent-launcher',page.evaluate_script("document.activeElement.classList.contains('agent-launcher') ? 'agent-launcher' : ''")
    click_button 'AI Agent'
    assert_selector '.copilot-message',text:'Registered salespeople: 1'
  end
  test "show assigned leads applies real DOM owner and stage controls and returns verified facts first" do
    @agent_steps=[['click_control','link: Leads'],['apply_filters','filter: Filter',[['select: Owner','Me'],['select: Status','New']]],['done','Done']]
    chat('Show leads assigned to me',copilot_plan(intent:'show_crm_data',query:'leads',status:'new',audience:'mine'))
    assert_current_path leads_path,ignore_query:true
    assert_equal @user.id.to_s,find('select[name=owner_id]').value
    assert_equal 'new',find('select[name=status]').value
    assert_selector '.copilot-message',text:'I found 1 new lead for your records.'
    assert_selector '.copilot-message',text:'The requested filtered page is open.'
    assert_equal 3,@agent_requests.size
    assert_nil @lead.reload.first_contact_at
    assert_equal 0,@lead.activities.count
  end
end
