# Explicit real provider check, never loaded by normal tests/CI. No customer database reads or writes.
abort "Set LEADCURRENT_LIVE_AGENT=1 to opt in." unless ENV["LEADCURRENT_LIVE_AGENT"] == "1"
abort "Live checks are local-test only." if ENV["CI"] || (ENV["RAILS_ENV"] && ENV["RAILS_ENV"] != "test")
ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "json"
require "fileutils"
body = { "model" => PageAgent::Protocol::MODEL, "messages" => [{ "role" => "system", "content" => "Safe Mode compatibility test" }, { "role" => "user", "content" => "Fictional compatibility test only. Finish now: use AgentOutput action done with success true. No DOM actions are needed." }],
  "tools" => [JSON.parse(JSON.generate(PageAgent::Protocol.tool))], "parallel_tool_calls" => false, "tool_choice" => { "type" => "function", "function" => { "name" => "AgentOutput" } } }
report = { started_at: Time.now.utc.iso8601, model: PageAgent::Protocol::MODEL, mocked: false, result: "BLOCKED", content_logged: false }
begin
  response = PageAgent::GroqClient.new.call(body)
  args = JSON.parse(response[:choices].sole[:message][:tool_calls].sole[:function][:arguments])
  raise PageAgent::Error.new(:invalid_response) unless args.dig("action", "done", "success") == true
  report.merge!(result: "PASS", named_function: "AgentOutput", usage: response[:usage])
rescue PageAgent::Error => error
  report[:result] = error.code == :configuration ? "BLOCKED" : "FAIL"
  report[:error_code] = error.code
ensure
  report[:finished_at] = Time.now.utc.iso8601
  FileUtils.mkdir_p(Rails.root.join(".local"))
  File.write(Rails.root.join(".local", "page-agent-compatibility.json"), JSON.pretty_generate(report))
  puts JSON.generate(report)
end
exit(report[:result] == "PASS" ? 0 : 1)
