require "json"
require "stringio"

# Bound and conceal only the token-authenticated intake body BEFORE Rails parses/logs params.
# Ordinary browser routes retain their existing sessions, request parsing and CSRF protection.
class AgentInquiryIngress
  MAX_BYTES = 16_384
  PATH = %r{\A/api/v1/agent_inquiries(?:\.json)?/?\z}
  def initialize(app) = @app = app
  def call(env)
    return @app.call(env) unless PATH.match?(env["PATH_INFO"].to_s)
    return error(405, "method_not_allowed", "Use POST for inquiry submission.", "Allow" => "POST") unless env["REQUEST_METHOD"] == "POST"
    return error(400, "invalid_request", "Do not supply query parameters.") unless env["QUERY_STRING"].to_s.empty?
    return error(415, "unsupported_media_type", "Send application/json.") unless env["CONTENT_TYPE"].to_s.split(";", 2).first.to_s.strip.downcase == "application/json"
    return error(413, "request_too_large", "Inquiry requests are limited to 16384 bytes.") if env["CONTENT_LENGTH"].to_i > MAX_BYTES
    body = env.fetch("rack.input").read(MAX_BYTES + 1).to_s
    return error(413, "request_too_large", "Inquiry requests are limited to 16384 bytes.") if body.bytesize > MAX_BYTES
    # Do not let automatic parameter parsing expose arbitrary attacker-controlled keys/values.
    env["action_dispatch.request.request_parameters"] = {}
    env["leadcurrent.agent_inquiry_body"] = body.force_encoding(Encoding::UTF_8)
    env["rack.input"] = StringIO.new(body)
    @app.call(env)
  end

  private
  def error(status, code, message, headers = {})
    [status, { "content-type" => "application/json; charset=utf-8", "cache-control" => "no-store" }.merge(headers), [JSON.generate(error: { code: code, message: message })]]
  end
end
