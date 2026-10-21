require "application_system_test_case"
require_relative "../support/page_agent_test_support"

class PageAgentBrowserTest < ApplicationSystemTestCase
  include PageAgentTestSupport
  setup do
    install_agent_fake
    @previous_wait=Capybara.default_max_wait_time
    Capybara.default_max_wait_time=12
    @user=make_user(role:'salesperson')
    @lead=make_lead(@user,created_at:28.hours.ago)
    @lead.update!(title:'Annual software subscription',notes:'PRIVATE_NOTE_CANARY Do not disclose customer history')
    page.driver.browser.execute_cdp('Emulation.clearDeviceMetricsOverride')
    @csp_probe=page.driver.browser.execute_cdp('Page.addScriptToEvaluateOnNewDocument',source:"window.agentCspViolations=0;document.addEventListener('securitypolicyviolation',()=>window.agentCspViolations++)")['identifier']
    page.current_window.resize_to(1440,1050)
  end
  teardown do
    Capybara.default_max_wait_time=@previous_wait
    page.driver.browser.execute_cdp('Page.removeScriptToEvaluateOnNewDocument',identifier:@csp_probe) if @csp_probe
    restore_agent_fake
  end
  def sign_in
    visit login_path
    fill_in 'Email address',with:@user.email
    fill_in 'Password',with:'test-password-123'
    click_button 'Sign in →'
    assert_text 'Make your next move count.'
  end
  def run_task(text)
    # Model-routing fixture only; production classification is performed by Groq, never keyword rules.
    @copilot_plan=case text
    when 'Find my overdue leads.' then copilot_plan(intent:'read_crm_data',query:'overdue_leads',audience:'mine',destination:'leads',navigate:true,action_task:text)
    when 'Open Atlas Industries.' then copilot_plan(intent:'page_action',destination:'record',search:'Atlas Industries',action_task:text)
    when 'Prepare a follow-up note for this customer.' then copilot_plan(intent:'page_action',destination:'note',action_task:text)
    when 'Read this page.' then copilot_plan(intent:'page_action',destination:'record',search:'Atlas Industries',action_task:text)
    else copilot_plan(intent:'page_action',destination:'leads',action_task:text)
    end
    click_button 'AI Agent'
    within '#agent-panel' do
      fill_in 'What would you like to do?',with:text
      click_button 'Run'
    end
  end
  def finished
    assert_selector '#leadcurrent-agent[data-status=completed]'
    assert_selector '#agent-panel li',visible: :all
    assert_selector '#agent-panel button:enabled',text:'Run'
    assert_equal 0,page.evaluate_script('window.agentCspViolations || 0')
  end
  test "official Page Agent executes actual Turbo navigation and overdue filters from model tool calls" do
    sign_in
    @agent_steps=[['click_control','link: Leads'],['choose_option','select: First contact','Overdue'],['choose_option','select: Owner','Me'],['click_control','filter: Filter'],['done','Overdue leads are visible.']]
    run_task('Find my overdue leads.')
    finished
    assert_current_path leads_path,ignore_query:true
    assert_equal 'overdue',page.find('select[name=attention]').value
    assert_equal @user.id.to_s,page.find('select[name=owner_id]').value
    assert_selector 'tbody .record-title',text:@lead.title
    assert_equal 5,@agent_requests.size
    assert_selector '#leadcurrent-agent',count:1
    assert_selector 'body.agent-open'
    assert @agent_requests.all?{|r|r.dig('tool_choice','function','name')=='AgentOutput'}
    assert @agent_requests.any?{|r|r['messages'].last['content'].include?('control_')}
    assert_equal 'new',@lead.reload.status
    assert_nil @lead.first_contact_at
    assert_equal 0,@lead.activities.count
    assert_equal 0,@lead.tasks.count
    page.go_back
    assert_selector '#leadcurrent-agent',count:1
    page.go_forward
    assert_selector '#leadcurrent-agent',count:1
    page.refresh
    assert_selector '#agent-panel',visible:false
    assert_no_selector '#leadcurrent-agent[data-status=thinking]'
    assert_equal 5,@agent_requests.size
  end
  test "official observation searches a company and opens its record while excluding private notes and contact fields" do
    sign_in
    visit leads_path
    @agent_steps=[['fill_field','search: Search','Atlas Industries'],['click_control','filter: Filter'],['click_control','link: Open Annual software subscription at Atlas Industries'],['done','Atlas record opened.']]
    run_task('Open Atlas Industries.')
    finished
    assert_current_path lead_path(@lead)
    assert_equal 4,@agent_requests.size
    serialized=@agent_requests.to_json
    assert_not serialized.include?('PRIVATE_NOTE_CANARY')
    assert_not serialized.include?(@lead.contact.email)
    assert_not serialized.include?(@user.email)
    assert_not serialized.include?(@agent_key)
    assert_not serialized.include?('Security & Password')
    assert_not serialized.include?('Mark qualified')
    assert_not(/control_\d+ (?:filter|link): Save action/.match?(serialized))
    assert_not serialized.include?('type="password"')
    assert_not page.html.include?(@agent_key)
  end
  test "agent prepares an unsaved note and only the real human submit records it without first contact or task effects" do
    sign_in
    visit lead_path(@lead)
    original=@lead.reload.attributes
    @agent_steps=[['fill_field','note: Prepare an unsaved follow-up note','Please confirm your seat count and procurement requirements.'],['done','Unsaved note prepared. Please review and save manually.']]
    run_task('Prepare a follow-up note for this customer.')
    finished
    assert_equal 'note',page.find('select[name=action_kind]').value
    assert_equal '',find_field('Next follow-up (optional)').value
    assert_equal 'Please confirm your seat count and procurement requirements.',find_field('What happened?').value
    assert_equal original,@lead.reload.attributes
    assert_equal 0,@lead.activities.count
    assert_equal 0,@lead.tasks.count
    click_button 'Save action'
    assert_text 'Note recorded.'
    assert_equal ['note'],@lead.activities.pluck(:kind)
    assert_nil @lead.reload.first_contact_at
    assert_equal 'new',@lead.status
    assert_equal 0,@lead.tasks.count
  end
  test "Stop cancels further execution duplicate run is blocked and forbidden tool controls never submit CRM changes" do
    sign_in
    visit lead_path(@lead)
    @agent_delay=1.5
    @agent_steps=[['done','Finished.']]
    run_task('Read this page.')
    assert_selector '#leadcurrent-agent[data-status=thinking]'
    page.execute_script("document.querySelector('#agent-panel form').requestSubmit()")
    within('#agent-panel'){click_button 'Stop'}
    assert_selector '#leadcurrent-agent[data-status=stopped]'
    assert_selector '#agent-panel button:enabled',text:'Run'
    sleep 1.6
    assert @agent_requests.size <= 1
    @agent_delay=0;@agent_action={'click_control'=>{'target'=>'control_9999'}}
    within('#agent-panel'){click_button 'Run'}
    assert_selector '#leadcurrent-agent[data-status=failed]'
    assert_equal 0,@lead.activities.count
    assert_equal 'new',@lead.reload.status
    @agent_action={'execute_javascript'=>{'script'=>'window.unsafeAgent=true'}}
    within('#agent-panel'){click_button 'Run'}
    assert_selector '#leadcurrent-agent[data-status=failed]'
    assert_not page.evaluate_script('Boolean(window.unsafeAgent)')
    assert_nil @lead.reload.first_contact_at
    page.current_window.resize_to(390,844)
    page.driver.browser.execute_cdp('Emulation.setDeviceMetricsOverride',width:390,height:844,deviceScaleFactor:1,mobile:true)
    %w[light dark].each do |theme|
      page.execute_script('document.documentElement.dataset.theme=arguments[0]',theme)
      assert page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')
      assert find_field('What would you like to do?').visible?
    end
    visit settings_path
    assert_no_selector '#leadcurrent-agent'
  end
  test "a filter changed to a write submit after observation is blocked before any submission" do
    sign_in
    visit leads_path
    original=@lead.reload.attributes
    @agent_delay=2
    @agent_steps=[['click_control','filter: Filter']]
    page.execute_script("window.agentUnsafeSubmits=0;document.querySelector('form.filters').addEventListener('submit',()=>window.agentUnsafeSubmits++)")
    run_task('Apply the visible filters.')
    Timeout.timeout(5) { sleep 0.01 until @agent_requests.any? }
    assert_includes @agent_requests.first['messages'].last['content'],'filter: Filter'
    page.execute_script("document.querySelector('form.filters input[type=submit]').setAttribute('formmethod','post')")
    assert_selector '#leadcurrent-agent[data-status=failed]'
    assert_equal 0,page.evaluate_script('window.agentUnsafeSubmits')
    assert_equal original,@lead.reload.attributes
    assert_equal 0,@lead.activities.count
    assert_equal 0,@lead.tasks.count
    assert_equal 1,@agent_requests.size
    assert_equal 0,page.evaluate_script('window.agentCspViolations')
  end
  test "existing unsaved form text is preserved and model HTML or rate failures remain safe text" do
    sign_in
    visit lead_path(@lead)
    fill_in 'What happened?',with:'PRIVATE_UNSAVED_USER_TEXT'
    @agent_steps=[['fill_field','note: Prepare an unsaved follow-up note','An attempted replacement.'],['done','Existing draft preserved.']]
    run_task('Prepare a follow-up note for this customer.')
    assert_selector '#leadcurrent-agent[data-status=failed]'
    assert_equal 'PRIVATE_UNSAVED_USER_TEXT',find_field('What happened?').value
    assert_equal 0,@lead.activities.count
    assert_not @agent_requests.to_json.include?('PRIVATE_UNSAVED_USER_TEXT')
    @agent_action={'done'=>{'text'=>'<img src=x onerror="window.agentPwned=true">','success'=>true}}
    @copilot_plan=copilot_plan(answer:'<img src=x onerror="window.agentPwned=true">')
    within('#agent-panel'){click_button 'Run'}
    assert_selector '#leadcurrent-agent[data-status=completed]'
    assert_text '<img src=x onerror="window.agentPwned=true">'
    assert_no_selector '#agent-panel img'
    assert_not page.evaluate_script('Boolean(window.agentPwned)')
    PageAgent::RequestGate::STORE.write("agent:daily:user:#{@user.id}",300)
    within('#agent-panel'){click_button 'Run'}
    assert_selector '#leadcurrent-agent[data-status=failed]'
    assert_text 'AI request limit reached'
    assert_selector '#agent-panel button:enabled',text:'Run'
    assert_nil @lead.reload.first_contact_at
  end
end
