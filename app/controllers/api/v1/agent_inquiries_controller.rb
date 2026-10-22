module Api
  module V1
    # Deliberately separate from ApplicationController: no session/cookie authentication,
    # browser redirects or CSRF exemption in the shared browser controller.
    class AgentInquiriesController < ActionController::API
      before_action :authenticate_agent
      rescue_from StandardError do |error|
        Rails.logger.error("agent_intake failure_class=#{error.class.name}")
        response.headers["Cache-Control"] = "no-store"
        render json: { error: { code: "unavailable", message: "Inquiry intake is temporarily unavailable. Retry with the same idempotency key." } }, status: :service_unavailable
      end
      rescue_from ActiveRecord::RecordInvalid do
        render_intake_error(AgentIntake::Error.new(:invalid_fields))
      end
      rescue_from AgentIntake::Error, with: :render_intake_error

      def create
        payload = AgentIntake::Payload.parse(request.env.fetch("leadcurrent.agent_inquiry_body", ""))
        inquiry, replayed = AgentIntake::Submit.call(credential: @credential, payload: payload, idempotency_key: request.headers["Idempotency-Key"])
        response.headers["Cache-Control"] = "no-store"
        render json: { inquiry_id: inquiry.id, status: inquiry.status, identity: "unverified", replayed: replayed }, status: replayed ? :ok : :created
      end

      private
      def authenticate_agent
        AgentIntake::RequestGate.ip!(request.remote_ip)
        match = /\A(?i:Bearer) (lc_agent_[a-f0-9]{24}\.[A-Za-z0-9_-]{43})\z/.match(request.authorization.to_s)
        @credential = AgentCredential.authenticate(match && match[1])
        raise AgentIntake::Error.new(:unauthorized) unless @credential
        AgentIntake::RequestGate.credential!(@credential)
      end
      def render_intake_error(error)
        response.headers["Cache-Control"] = "no-store"
        response.headers["WWW-Authenticate"] = 'Bearer realm="LeadCurrent agent inquiries"' if error.status == 401
        response.headers["Retry-After"] = "60" if error.status == 429
        render json: { error: { code: error.code, message: error.message } }, status: error.status
      end
    end
  end
end
