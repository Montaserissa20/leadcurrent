module PageAgent
  class CompletionsController < ApplicationController
    rescue_from ActionDispatch::Http::Parameters::ParseError do
      render_error(PageAgent::Error.new(:invalid_request))
    end
    def create
      response.headers["Cache-Control"] = "no-store"
      raise Error.new(:invalid_request) unless request.media_type == "application/json" && request.raw_post.bytesize <= Protocol::MAX_BODY_BYTES
      input = JSON.parse(request.raw_post)
      basic=%w[agent_request page_path]
      contextual=%w[agent_request page_path page_query conversation_id run_id note_present]
      raise Error.new(:invalid_request) unless input.is_a?(Hash) && [basic.sort,contextual.sort].include?(input.keys.sort)
      path = input["page_path"]
      raise Error.new(:invalid_request) unless path.is_a?(String) && path.match?(%r{\A(?:/|/(?:leads|opportunities|tasks|analytics|pipeline|activity)|/(?:leads|opportunities)/\d+)\z})
      if (match = path.match(%r{\A/(leads|opportunities)/(\d+)\z}))
        scope(match[1] == "leads" ? Lead : Opportunity).find(match[2])
      end
      # Validate even when configuration is missing; never forward arbitrary provider options.
      Protocol.request!(input["agent_request"])
      done_allowed = true
      completion_only = false
      if input.key?('conversation_id')
        raise Error.new(:invalid_request) unless input['run_id'].is_a?(String) && input['run_id'].match?(/\A[0-9a-f]{32}\z/) && [true,false].include?(input['note_present']) && input['page_query'].is_a?(String) && input['page_query'].bytesize <= 1_000
        conversation=Copilot::Conversation.new(current_user,session[:login_session_id],input['conversation_id'])
        plan=conversation.peek(input['run_id'])
        done_allowed=Copilot::Outcome.verified?(current_user,plan,input.merge('execution_error'=>false))
        completion_only=done_allowed
      end
      result = RequestGate.call(current_user) { GroqClient.new.call(input["agent_request"],done_allowed:done_allowed,completion_only:completion_only) }
      render json: result
    rescue JSON::ParserError
      render_error(Error.new(:invalid_request))
    rescue PageAgent::Error => error
      render_error(error)
    end

    private
    def render_error(error)
      status = case error.code
      when :invalid_request, :context_limit then :unprocessable_entity
      when :rate_limited then :too_many_requests
      when :busy then :conflict
      when :timeout then :gateway_timeout
      when :invalid_response then :bad_gateway
      else :service_unavailable
      end
      response.headers["Cache-Control"] = "no-store"
      response.headers["Retry-After"] = error.retry_after.to_s if error.retry_after
      render json: { error: { code: error.code, message: error.message } }, status: status
    end
  end
end
