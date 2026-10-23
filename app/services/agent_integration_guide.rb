require "yaml"

# Public examples are derived only from the checked-in contract, never CRM data/credentials.
class AgentIntegrationGuide
  SPEC_PATH = Rails.root.join("docs/api/agent-inquiries.openapi.yaml")
  attr_reader :base_url

  def initialize(base_url:)
    # Host headers must not become shell/code syntax in copyable examples.
    raise ArgumentError, "Invalid documentation origin" unless base_url.match?(%r{\Ahttps?://(?:[A-Za-z0-9.-]+|\[[A-Fa-f0-9:]+\])(?::\d{1,5})?\z})
    @base_url = base_url
  end

  def self.specification = YAML.safe_load_file(SPEC_PATH, aliases: false)
  def endpoint_path = Rails.application.routes.url_helpers.api_v1_agent_inquiries_path
  def endpoint = base_url + endpoint_path
  def payload = self.class.specification.fetch("paths").fetch(endpoint_path).fetch("post").fetch("requestBody").fetch("content").fetch("application/json").fetch("example")
  def json_payload = JSON.pretty_generate(payload)

  def examples
    {
      "curl" => <<~BASH,
        # Creates a real fictional inquiry. Set LEADCURRENT_AGENT_TOKEN privately first.
        LEADCURRENT_BASE_URL='#{base_url}'
        INQUIRY_KEY="demo-$(date +%s)-$RANDOM-$RANDOM"
        curl --fail-with-body --request POST "$LEADCURRENT_BASE_URL#{endpoint_path}" \\
          --header "Authorization: Bearer $LEADCURRENT_AGENT_TOKEN" \\
          --header 'Content-Type: application/json' \\
          --header "Idempotency-Key: $INQUIRY_KEY" \\
          --data-binary @- <<'JSON'
        #{json_payload}
        JSON
      BASH
      "powershell" => <<~POWERSHELL,
        # Creates a real fictional inquiry. Set LEADCURRENT_AGENT_TOKEN privately first.
        $baseUrl = '#{base_url}'
        $inquiryKey = [guid]::NewGuid().ToString('N')
        $headers = @{ Authorization = "Bearer $env:LEADCURRENT_AGENT_TOKEN"; 'Idempotency-Key' = $inquiryKey }
        $body = @'
        #{json_payload}
        '@
        Invoke-RestMethod -Method Post -Uri "$baseUrl#{endpoint_path}" -Headers $headers -ContentType 'application/json' -Body $body
      POWERSHELL
      "python" => <<~PYTHON
        # Creates a real fictional inquiry. Standard library only; no AI/provider needed.
        import json, os, urllib.error, urllib.request, uuid
        base_url = #{base_url.to_json}
        token = os.environ["LEADCURRENT_AGENT_TOKEN"]
        inquiry_key = uuid.uuid4().hex
        payload = json.loads(#{json_payload.to_json})
        class NoRedirect(urllib.request.HTTPRedirectHandler):
            def redirect_request(self, req, fp, code, msg, headers, newurl):
                return None
        request = urllib.request.Request(base_url + "#{endpoint_path}", method="POST",
            data=json.dumps(payload).encode("utf-8"), headers={"Content-Type": "application/json",
            "Authorization": "Bearer " + token, "Idempotency-Key": inquiry_key})
        try:
            with urllib.request.build_opener(NoRedirect()).open(request, timeout=25) as response:
                print(response.status, response.read(32768).decode("utf-8"))
        except urllib.error.HTTPError as error:
            print("HTTP", error.code, "— check the documented status; keep the same body/key for retry.")
        except (urllib.error.URLError, TimeoutError):
            print("Connection failed; check the server and retry with the same body/key.")
      PYTHON
    }
  end
end
