# Explicit real Groq + official Page Agent acceptance; fictional test transaction rolls back.
abort 'Set LEADCURRENT_LIVE_AGENT=1 to opt in.' unless ENV['LEADCURRENT_LIVE_AGENT']=='1'
abort 'Local test only.' if ENV['CI'] || (ENV['RAILS_ENV'] && ENV['RAILS_ENV']!='test')
abort 'GROQ_API_KEY missing.' if ENV.fetch('GROQ_API_KEY','').strip.empty?
ENV['RAILS_ENV']='test'
$LOAD_PATH.unshift(File.expand_path('../test',__dir__))
require_relative '../test/application_system_test_case'
require 'json'
require 'fileutils'

class LiveCopilotFinalizationCheck < ApplicationSystemTestCase
  test 'real language team facts follow-ups scoped CRM and actual safe DOM execution' do
    report={started_at:Time.now.utc.iso8601,result:'FAIL',mocked:false,scenarios:[],completions:[],decisions:[],failures:[],paid_cost:'not measured',human_hours:'not measured'}
    subscriptions=%w[completion.copilot completion.page_agent decision.copilot invalid_decision.copilot failure.page_agent].map do |name|
      ActiveSupport::Notifications.subscribe(name) do |_n,_s,_f,_id,payload|
        if name=='invalid_decision.copilot'
          report[:failures]<<payload.slice('intent','query','audience','status','period','destination').merge(surface:name)
        elsif name=='decision.copilot'
          report[:decisions]<<payload.slice('intent','query','audience','status','period','destination','navigate')
        elsif name.start_with?('completion')
          report[:completions]<<payload.slice(:model,:usage,:action,:duration_seconds).merge(surface:name)
        else
          report[:failures]<<payload.slice(:status,:code,:generated_function,:action_wrapper,:done_action,:generation_shape)
        end
      end
    end
    previous=Capybara.default_max_wait_time;Capybara.default_max_wait_time=20
    probe=page.driver.browser.execute_cdp('Page.addScriptToEvaluateOnNewDocument',source:"window.finalCsp=0;document.addEventListener('securitypolicyviolation',()=>window.finalCsp++)")['identifier']
    page.driver.browser.execute_cdp('Emulation.clearDeviceMetricsOverride');page.current_window.resize_to(1440,1050)
    user=make_user(role:'salesperson')
    colleague=make_user(organization:user.organization,role:'salesperson')
    manager=make_user(organization:user.organization)
    lead=make_lead(user,created_at:28.hours.ago);lead.update!(title:'Fictional Atlas subscription',notes:'PRIVATE_CUSTOMER_CANARY')
    other=make_lead(colleague,created_at:32.hours.ago);other.company.update!(name:'Fictional Cedar Company')
    deal=make_opportunity(user);deal.company.update!(name:'Fictional Nova Company')
    OpportunityTransition.call(deal,actor:user,to:'proposal');OpportunityTransition.call(deal,actor:user,to:'negotiation')
    colleague_deal=make_opportunity(colleague);colleague_deal.company.update!(name:'Fictional Colleague Deal Company')
    OpportunityTransition.call(colleague_deal,actor:colleague,to:'proposal');OpportunityTransition.call(colleague_deal,actor:colleague,to:'negotiation')
    task=Task.create!(organization:user.organization,owner:user,lead:lead,title:'Fictional review today',due_at:Time.current.in_time_zone(user.time_zone).beginning_of_day+12.hours)
    foreign=make_user;make_lead(foreign,created_at:40.hours.ago)
    models=[Organization,User,Company,Contact,Lead,Opportunity,Activity,Task,AuditEvent]
    original=models.to_h{|model|[model.name,model.order(:id).map(&:attributes)]}
    team=WorkspaceAccess.scope(user,User).group(:role).count
    leads=WorkspaceAccess.scope(user,Lead)
    overdue=leads.overdue.order(:first_contact_deadline,:id).to_a
    urgent=NextBestAction.new(user).call(record:lead,limit:1).first
    report[:expected_facts]={team_total:team.values.sum,team_roles:team,leads:leads.count,overdue:overdue.size,today_followups:WorkspaceAccess.scope(user,Task).pending.where(owner_id:user.id,due_at:Time.current.in_time_zone(user.time_zone).all_day).count,urgent_priority:urgent.priority,negotiation:WorkspaceAccess.scope(user,Opportunity).where(owner_id:user.id,status:'negotiation').count}
    visit login_path;fill_in 'Email address',with:user.email;fill_in 'Password',with:'test-password-123';click_button 'Sign in →'
    assert_text 'Make your next move count.';click_button 'AI Agent'
    questions=[
      ['Tell me how I can use the system.','help'],
      ['How many users are in my team?','team'],
      ['How many of them are salespeople?','salespeople'],
      ['How many leads do we have?','lead_count'],
      ['Which leads are overdue?','overdue'],
      ['Which one needs attention first?','urgent'],
      ['Show my opportunities in negotiation.','negotiation'],
      ['What follow-ups are due today?','tasks'],
      ['Open Atlas Industries.','record'],
      ['Prepare a follow-up note for this customer.','note'],
      ['How many people are working with me?','team'],
      ["What's the size of our sales team?",'team'],
      ['Do we have more than three users?','team']
    ]
    if ENV['LEADCURRENT_LIVE_SCENARIOS']
      selected=ENV['LEADCURRENT_LIVE_SCENARIOS'].split(',')
      abort 'Unknown diagnostic scenario' unless (selected-questions.map(&:last)).empty?
      questions=questions.select{|_question,expected|selected.include?(expected)}
      report[:diagnostic_subset]=selected
      if selected.first=='record'
        visit opportunities_path(owner_id:user.id,status:'negotiation');click_button 'AI Agent'
        report[:manual_fixture_start]='Existing filtered Opportunities page; subsequent navigation must use real Page Agent.'
      elsif selected.first=='note'
        visit lead_path(lead);click_button 'AI Agent'
        report[:manual_fixture_start]='Existing editable lead page; note preparation must use real Page Agent.'
      end
    end
    questions.each do |question,expected|
      # Test-only pacing for a rapid scripted conversation. Never clear/increase any
      # application/provider limit; reserve room for the existing six-step DOM bound.
      # These waits are reported separately from the measured request latency.
      anticipated=%w[negotiation record note].include?(expected) ? 7 : 1
      wait_started=Process.clock_gettime(Process::CLOCK_MONOTONIC)
      loop do
        budgets={"agent:user:#{user.id}"=>8,"agent:workspace:#{user.organization_id}"=>12,'provider:groq'=>16}
        waits=budgets.filter_map do |key,limit|
          count=PageAgent::RequestGate::STORE.read(key).to_i
          next unless count+anticipated>limit
          reset=PageAgent::RequestGate::STORE.read("agent:reset:#{key}")||1.minute.from_now.to_f
          [reset-Time.current.to_f,0].max
        end
        token_state=PageAgent::Pacing::STORE.read(PageAgent::Pacing::KEY)
        if token_state && (anticipated>1 || token_state[:cooldown] || token_state[:remaining]<3500)
          waits << [token_state[:reset_at]-Time.current.to_f,0].max
        end
        seconds=waits.max.to_f.ceil
        break if seconds<=0
        puts JSON.generate(test_harness_quota_wait_seconds:seconds,before:expected)
        sleep [seconds,30].min
      end
      quota_wait=(Process.clock_gettime(Process::CLOCK_MONOTONIC)-wait_started).round(3)
      started=Process.clock_gettime(Process::CLOCK_MONOTONIC)
      before_calls=report[:completions].size
      within('#agent-panel'){fill_in 'What would you like to do?',with:question;click_button 'Run'}
      assert_selector '#leadcurrent-agent[data-status=completed], #leadcurrent-agent[data-status=failed]',wait:240
      assert_selector '#leadcurrent-agent[data-status=completed]',wait:0
      answer=page.all('.copilot-message[data-role=assistant]').last
      case expected
      when 'help'
        assert_includes answer.text,'AI explanation'
        assert_match(/lead|opportunit|follow.up/i,answer.text)
      when 'team','salespeople'
        assert_includes answer.text,"#{team.values.sum} registered users, including you"
        assert_includes answer.text,"#{team.fetch('salesperson')} salespeople"
        assert_includes answer.text,'online status is unknown'
        assert_equal 'team_summary',report[:decisions].last['query']
        assert_equal 'salesperson',report[:decisions].last['status'] if expected=='salespeople'
      when 'lead_count'
        assert_includes answer.text,"#{leads.count} leads"
      when 'overdue'
        assert_match(/#{overdue.size} overdue leads/,answer.text)
        overdue.each{|record|within(answer){assert_link record.title,href:lead_path(record)}}
      when 'urgent'
        assert_equal 'overdue_leads',report[:decisions].last['query']
        within(answer){assert_link lead.title,href:lead_path(lead)}
        assert_includes answer.text,"Priority #{urgent.priority}:"
      when 'negotiation'
        assert_current_path opportunities_path,ignore_query:true
        assert_equal user.id.to_s,find('select[name=owner_id]').value
        assert_equal 'negotiation',find('select[name=status]').value
        assert_includes answer.text,'1 negotiation opportunity'
        within(answer){assert_link deal.title,href:opportunity_path(deal)}
      when 'tasks'
        assert_includes answer.text,"#{report[:expected_facts][:today_followups]} today pending follow-up"
        assert_includes answer.text,task.title
        assert_equal 'today',report[:decisions].last['period']
      when 'record'
        assert_current_path lead_path(lead)
        assert_includes answer.text,lead.company.name
      when 'note'
        assert_equal 'note',find('select[name=action_kind]').value
        assert find_field('What happened?').value.present?
        assert_equal '',find_field('Next follow-up (optional)').value
        assert_includes answer.text,'unsaved note'
      end
      assert_includes answer.text,'Verified CRM data' unless %w[help record note].include?(expected)
      if !%w[negotiation record note].include?(expected)
        assert report[:completions][before_calls..].none?{|completion|completion[:surface]=='completion.page_agent'}
      end
      assert_equal original,models.to_h{|model|[model.name,model.order(:id).map(&:attributes)]}
      assert_equal 0,page.evaluate_script('window.finalCsp')
      assert_no_selector '.agent-activity[open]'
      assert_not page.html.include?(ENV.fetch('GROQ_API_KEY'))
      row={question:question,expected:expected,result:'PASS',seconds:(Process.clock_gettime(Process::CLOCK_MONOTONIC)-started).round(3),test_harness_wait_seconds:quota_wait,calls:report[:completions].size-before_calls,crm_unchanged:true}
      report[:scenarios]<<row;puts JSON.generate(row)
      if expected=='team'
        FileUtils.mkdir_p(Rails.root.join('.local','copilot-final-preview'))
        save_screenshot(Rails.root.join('.local','copilot-final-preview','team.png'))
      end
    end
    report[:note_submission]='No submit occurred; all CRM table contents unchanged after every request. No manual save was performed.'
    report[:result]='PASS'
  ensure
    subscriptions&.each{|subscription|ActiveSupport::Notifications.unsubscribe(subscription)}
    Capybara.default_max_wait_time=previous if previous
    if report
      report[:finished_at]=Time.now.utc.iso8601
      report[:csp_violations]=page.evaluate_script('window.finalCsp || 0') rescue nil
      report[:diagnostic]=page.evaluate_script("(()=>{const c=window.Stimulus?.getControllerForElementAndIdentifier(document.getElementById('leadcurrent-agent'),'page-agent');return {status:c?.element?.dataset.status||null,failure:c?.failureCode||null,proxyError:c?.proxyErrorCode||null,lastAttempt:c?.lastAttempt||null}})()") rescue nil
      report[:usage]=report[:completions].each_with_object(Hash.new(0)){|entry,sum|entry.fetch(:usage,{}).each{|key,value|sum[key]+=value}}
      FileUtils.mkdir_p(Rails.root.join('.local'))
      path=Rails.root.join('.local',"copilot-final-live-#{report[:started_at].delete('^0-9')}.json")
      File.write(path,JSON.pretty_generate(report))
      File.write(Rails.root.join('.local','copilot-final-live.json'),JSON.pretty_generate(report))
      puts JSON.generate(report.slice(:result,:started_at,:finished_at,:usage))
    end
    page.driver.browser.execute_cdp('Page.removeScriptToEvaluateOnNewDocument',identifier:probe) if probe
  end
end
