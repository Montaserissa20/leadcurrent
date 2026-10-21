module Copilot
  class MessagesController < ApplicationController
    rescue_from PageAgent::Error, with: :render_error
    rescue_from ActionDispatch::Http::Parameters::ParseError do
      render_error(PageAgent::Error.new(:invalid_request))
    end
    def create
      input = read_input!(%w[message page_path conversation_id])
      result = Assistant.new(current_user,session[:login_session_id],input["conversation_id"]).call(message:input["message"],page_path:input["page_path"])
      render json:result
    end

    def outcome
      input = read_input!(%w[conversation_id run_id page_path page_query note_present agent_success execution_error])
      raise PageAgent::Error.new(:invalid_request) unless input.keys.sort == %w[conversation_id run_id page_path page_query note_present agent_success execution_error].sort &&
        [true,false].include?(input["execution_error"]) && [true,false].include?(input["note_present"]) && [true,false].include?(input["agent_success"]) && input["run_id"].is_a?(String) && input["run_id"].match?(/\A[0-9a-f]{32}\z/)
      render json:Assistant.new(current_user,session[:login_session_id],input["conversation_id"]).finish(input)
    end

    private
    def read_input!(allowed)
      response.headers["Cache-Control"] = "no-store"
      raise PageAgent::Error.new(:invalid_request) unless request.media_type == "application/json" && request.raw_post.bytesize <= 4_000
      input = JSON.parse(request.raw_post)
      raise PageAgent::Error.new(:invalid_request) unless input.is_a?(Hash) && (input.keys-allowed).empty?
      input
    rescue JSON::ParserError
      raise PageAgent::Error.new(:invalid_request)
    end
    def render_error(error)
      status = case error.code
      when :invalid_request, :context_limit then :unprocessable_entity
      when :rate_limited then :too_many_requests
      when :busy, :conversation_expired then :conflict
      when :timeout then :gateway_timeout
      when :invalid_response then :bad_gateway
      else :service_unavailable
      end
      response.headers["Cache-Control"] = "no-store"
      response.headers["Retry-After"] = error.retry_after.to_s if error.retry_after
      render json:{error:{code:error.code,message:error.message}},status:status
    end
  end
end
