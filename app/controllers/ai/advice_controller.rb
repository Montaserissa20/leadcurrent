module Ai
  class AdviceController < ApplicationController
    before_action :load_customer

    def create
      response.headers["Cache-Control"] = "no-store"
      @mode = params[:mode].to_s
      question = params[:question] || ""
      SalesAdvisor.validate!(@mode, question)
      @context = CustomerContext.new(current_user, @record)
      @result = RequestGate.call(current_user) do
        SalesAdvisor.new.call(context: @context, mode: @mode, question: question)
      end
      render :create
    rescue Ai::Error => error
      @ai_error = error.message
      response.headers["Cache-Control"] = "no-store"
      status = case error.code
      when :invalid_request, :context_limit then :unprocessable_entity
      when :rate_limited then :too_many_requests
      when :busy then :conflict
      when :timeout then :gateway_timeout
      when :invalid_response then :bad_gateway
      else :service_unavailable
      end
      render :create, status: status
    end

    private
    def load_customer
      # Path parameters select the record; submitted IDs/context cannot override it.
      path = request.path_parameters
      model, id = path[:lead_id] ? [Lead, path[:lead_id]] : [Opportunity, path[:opportunity_id]]
      @record = scope(model).find(id)
    end
  end
end
