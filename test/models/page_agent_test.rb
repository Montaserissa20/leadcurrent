require "test_helper"
require_relative "../support/page_agent_test_support"

class PageAgentTest < ActiveSupport::TestCase
  include PageAgentTestSupport
  setup { install_agent_fake }
  teardown { restore_agent_fake }

  test "separate TLS Groq transport fixes model policy token limits and preserves the named function call" do
    reply = PageAgent::GroqClient.new.call(agent_body("Fictional person@example.test +90 555 123 4567 #{@agent_key}"))
    sent = @agent_requests.sole
    assert_equal "https://api.groq.com/openai/v1/chat/completions", PageAgent::GroqClient::ENDPOINT.to_s
    assert_equal "Bearer #{@agent_key}", @agent_authorization
    assert @agent_http.use_ssl
    assert_equal OpenSSL::SSL::VERIFY_PEER, @agent_http.verify_mode
    assert_equal [3,15,5,0], [@agent_http.open_timeout,@agent_http.read_timeout,@agent_http.write_timeout,@agent_http.max_retries]
    assert_equal PageAgent::Protocol::POLICY, sent["messages"].first["content"]
    assert_not sent.to_json.include?(@agent_key)
    assert_not sent.to_json.include?("person@example.test")
    assert_not sent.to_json.include?("+90 555")
    assert_equal 512, sent["max_completion_tokens"]
    assert_equal false, sent["parallel_tool_calls"]
    assert_equal false, sent["stream"]
    assert_equal "low", sent["reasoning_effort"]
    assert_equal "AgentOutput", sent.dig("tools",0,"function","name")
    assert_equal true,sent.dig('tools',0,'function','strict')
    assert_equal ['action'],sent.dig('tools',0,'function','parameters','properties').keys
    assert_equal PageAgent::Protocol.tool.as_json, sent["tools"].sole
    call = reply[:choices].sole[:message][:tool_calls].sole
    assert_equal "call_fixture", call[:id]
    assert_equal "AgentOutput", call[:function][:name]
    assert_equal true, JSON.parse(call[:function][:arguments]).dig("action","done","success")
    assert_equal({ "prompt_tokens" => 100, "completion_tokens" => 30, "total_tokens" => 130 }, reply[:usage])
  end

  test "arbitrary URLs keys models methods schemas and malformed messages are not forwarded" do
    bad = [agent_body.merge("baseURL" => "https://attacker.test"),agent_body.merge("apiKey" => @agent_key),agent_body.merge("model" => "other-model"),agent_body.merge("stream" => true),agent_body.merge("parallel_tool_calls" => true),agent_body.merge("tool_choice" => "auto"),agent_body.merge("messages" => [{"role"=>"system","content"=>"a"}]),agent_body.merge("messages" => [{"role"=>"system","content"=>"a"},{"role"=>"user","content"=>[{}]}]),agent_body("x"*16001),agent_body.merge("tools" => [{"type"=>"function","function"=>{"name"=>"execute_javascript"}}])]
    bad.each { |body| assert_equal :invalid_request, assert_raises(PageAgent::Error) { PageAgent::GroqClient.new.call(body) }.code }
    assert_empty @agent_requests
    hostile = agent_body
    hostile["tools"][0]["function"]["parameters"] = { "arbitrary_attack" => "execute scripts" }
    PageAgent::GroqClient.new.call(hostile)
    assert_equal PageAgent::Protocol.tool.as_json, @agent_requests.sole["tools"].sole
  end

  test "missing key provider failure and network errors have fixed messages without retries" do
    ENV.delete("GROQ_API_KEY")
    assert_equal :configuration, assert_raises(PageAgent::Error) { PageAgent::GroqClient.new.call(agent_body) }.code
    assert_empty @agent_requests
    ENV["GROQ_API_KEY"] = @agent_key
    {401=>:provider_auth,403=>:provider_auth,429=>:rate_limited,400=>:model_unavailable,404=>:model_unavailable,422=>:model_unavailable,500=>:unavailable}.each do |status,code|
      @agent_status=status;@agent_raw="sensitive #{@agent_key}"
      error=assert_raises(PageAgent::Error) { PageAgent::GroqClient.new.call(agent_body) }
      assert_equal code,error.code
      assert_not error.message.include?(@agent_key)
    end
    assert_equal 7,@agent_requests.size
    [Net::ReadTimeout.new,Net::OpenTimeout.new,Timeout::Error.new].each do |failure|
      @agent_exception=failure
      assert_equal :timeout,assert_raises(PageAgent::Error) { PageAgent::GroqClient.new.call(agent_body) }.code
    end
    @agent_exception=SocketError.new
    assert_equal :unavailable,assert_raises(PageAgent::Error) { PageAgent::GroqClient.new.call(agent_body) }.code
  end

  test "provider tool generation failure is distinguished without leaking failed generation" do
    @agent_status=400
    @agent_raw=JSON.generate(error:{code:'tool_use_failed',failed_generation:"private output #{@agent_key}"})
    events=[]
    listener=ActiveSupport::Notifications.subscribe('failure.page_agent') { |_n,_s,_f,_id,payload| events << payload }
    error=assert_raises(PageAgent::Error) { PageAgent::GroqClient.new.call(agent_body) }
    assert_equal :tool_call_failed,error.code
    assert_not error.message.include?(@agent_key)
    assert_not error.message.include?('private output')
    assert_equal({status:400,code:'tool_use_failed'},events.sole)
  ensure
    ActiveSupport::Notifications.unsubscribe(listener) if listener
  end

  test "workspace and shared provider quotas span multiple accounts" do
    first=make_user
    second=make_user(organization:first.organization)
    8.times { PageAgent::RequestGate.call(first) {} }
    4.times { PageAgent::RequestGate.call(second) {} }
    assert_equal :rate_limited,assert_raises(PageAgent::Error) { PageAgent::RequestGate.call(second) {} }.code
    other=make_user
    4.times { PageAgent::RequestGate.call(other) {} }
    assert_equal :rate_limited,assert_raises(PageAgent::Error) { PageAgent::RequestGate.call(make_user) {} }.code
  end

  test "malformed oversized multiple or dangerous tool output is rejected and credentials are redacted" do
    ["not json","null","[]","{}","x"*24577,JSON.generate(model:PageAgent::Protocol::MODEL,choices:[])].each do |raw|
      @agent_raw=raw
      assert_equal :invalid_response,assert_raises(PageAgent::Error) { PageAgent::GroqClient.new.call(agent_body) }.code
    end
    @agent_raw=nil
    [{"execute_javascript"=>{"script"=>"alert(1)"}},{"click_control"=>{"target"=>"https://evil.test"}},{"done"=>{"text"=>"x","success"=>"true"}},{"fill_field"=>{"target"=>"control_1","text"=>"x"*601}},{"click_control"=>{"target"=>"control_1"},"done"=>{"text"=>"x","success"=>true}}].each do |action|
      @agent_action=action
      assert_raises(PageAgent::Error) { PageAgent::GroqClient.new.call(agent_body) }
    end
    @agent_action={"done"=>{"text"=>"#{@agent_key} a@example.test","success"=>true}}
    reply=PageAgent::GroqClient.new.call(agent_body)
    assert_not reply.to_json.include?(@agent_key)
    assert_not reply.to_json.include?("a@example.test")
  end

  test "process-local limiter prevents overlap minute and daily overuse while releasing errors" do
    user=make_user
    PageAgent::RequestGate.call(user) do
      assert_equal :busy,assert_raises(PageAgent::Error) { PageAgent::RequestGate.call(user) { flunk } }.code
      assert_equal :busy,assert_raises(PageAgent::Error) { PageAgent::RequestGate.call(user) { flunk } }.code
    end
    assert_raises(PageAgent::Error) { PageAgent::RequestGate.call(user) { raise PageAgent::Error.new(:timeout) } }
    6.times { PageAgent::RequestGate.call(user) {} }
    assert_equal :rate_limited,assert_raises(PageAgent::Error) { PageAgent::RequestGate.call(user) {} }.code
    travel_to 61.seconds.from_now do
      assert_equal :ok,PageAgent::RequestGate.call(user) { :ok }
      PageAgent::RequestGate::STORE.write("agent:daily:user:#{user.id}",300)
      assert_equal :rate_limited,assert_raises(PageAgent::Error) { PageAgent::RequestGate.call(user) {} }.code
    end
  end
  test "Phase 1 and Page Agent share provider budget and in-flight ownership" do
    user=make_user
    Ai::RequestGate.call(user) do
      assert_equal :busy,assert_raises(PageAgent::Error) { PageAgent::RequestGate.call(user) {} }.code
    end
    PageAgent::RequestGate.call(user) do
      assert_equal :busy,assert_raises(Ai::Error) { Ai::RequestGate.call(user) {} }.code
    end
    PageAgent::RequestGate::STORE.write('provider:groq',16)
    assert_equal :rate_limited,assert_raises(PageAgent::Error) { PageAgent::RequestGate.call(make_user) {} }.code
    assert_equal :ok,Ai::RequestGate.call(make_user) { :ok }
  end
  test "malformed provider diagnostics remain safe and never crash on nonobject function arguments" do
    @agent_arguments={'action'=>{'apply_filters'=>"private #{@agent_key}"}}
    error=assert_raises(PageAgent::Error){PageAgent::GroqClient.new.call(agent_body)}
    assert_equal :invalid_response,error.code
    assert_not error.message.include?(@agent_key)
    @agent_raw=JSON.generate(model:PageAgent::Protocol::MODEL,choices:[{finish_reason:'tool_calls',message:{role:'assistant',tool_calls:[{id:'call_bad',type:'function',function:"private #{@agent_key}"}]}}])
    error=assert_raises(PageAgent::Error){PageAgent::GroqClient.new.call(agent_body)}
    assert_equal :invalid_response,error.code
    assert_not error.message.include?(@agent_key)
  end
end
