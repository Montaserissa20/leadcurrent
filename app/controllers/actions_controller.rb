class ActionsController < ApplicationController
  def create
    model = { "Lead" => Lead, "Opportunity" => Opportunity }[params[:record_type]]
    raise WorkflowError, "Choose a lead or opportunity" unless model
    record = scope(model).find(params[:record_id])
    case params[:action_kind]
    when "contact", "note"
      body = params[:body].to_s
      if params[:action_kind] == "contact" && params[:contact_method].present?
        raise WorkflowError, "Choose a valid contact method" unless params[:contact_method].in?(%w[call meeting message])
        raise WorkflowError, "Describe the conversation" if body.blank?
        body = "[#{params[:contact_method].humanize}] #{body}"
      end
      RecordActivity.call(record, actor: current_user, kind: params[:action_kind], body: body, follow_up_at: parse_time(params[:follow_up_at]))
      message = "#{params[:action_kind].humanize} recorded."
      message += " Follow-up scheduled." if params[:follow_up_at].present?
    when "follow_up"
      ScheduleFollowUp.call(record, actor: current_user, due_at: parse_time(params[:follow_up_at]))
      message = "Follow-up scheduled."
    else
      raise WorkflowError, "Choose a valid action"
    end
    redirect_to params[:from_dashboard] == "true" ? root_path : polymorphic_path(record), notice: message, status: :see_other
  end
end
