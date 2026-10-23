class AgentIntegrationsController < ApplicationController
  # Only these GET documentation routes are public. All API/management guards stay intact.
  skip_before_action :require_login, :require_password_change, only: %i[index openapi]
  layout "agent_integrations"

  def index
    @guide = AgentIntegrationGuide.new(base_url: request.base_url)
    response.headers["Cache-Control"] = "no-store"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Link"] = "<#{agent_inquiries_openapi_path}>; rel=\"service-desc\"; type=\"application/yaml\""
  end

  def openapi
    response.headers["X-Content-Type-Options"] = "nosniff"
    send_data File.binread(AgentIntegrationGuide::SPEC_PATH), type: "application/yaml", disposition: "attachment", filename: "agent-inquiries.openapi.yaml"
  end
end
