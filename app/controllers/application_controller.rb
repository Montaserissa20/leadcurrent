class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :require_login
  around_action :use_user_time_zone
  helper_method :current_user, :editable?
  rescue_from ActiveRecord::RecordNotFound do
    render "shared/error", locals: { message: "This record is unavailable in your workspace." }, status: :not_found
  end
  rescue_from WorkflowError, ActiveRecord::RecordInvalid do |error|
    render "shared/error", locals: { message: error.message }, status: :unprocessable_entity
  end
  private
  def current_user
    return @current_user if defined?(@current_user)
    @login_session = Session.includes(:user).find_by(id: session[:login_session_id])
    @current_user = @login_session&.expires_at&.future? ? @login_session.user : nil
  end
  def require_login
    redirect_to login_path unless current_user
  end
  def use_user_time_zone(&block)
    Time.use_zone(current_user&.time_zone || "Europe/Istanbul", &block)
  end
  def scope(model) = WorkspaceAccess.scope(current_user, model)
  def editable?(record) = current_user && record.organization_id == current_user.organization_id && (current_user.manager? || !record.respond_to?(:owner_id) || record.owner_id == current_user.id)
  def start_session(user)
    reset_session
    login_session = Session.create!(user: user, expires_at: 12.hours.from_now)
    session[:login_session_id] = login_session.id
  end
  def parse_time(value)
    return nil if value.blank?
    Time.zone.parse(value)
  rescue ArgumentError, TypeError
    raise WorkflowError, "Choose a valid follow-up date and time"
  end
  def filter_records(records)
    records = records.where("title ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)}%") if params[:q].present?
    records = records.where(status: params[:status]) if params[:status].present?
    records = records.where(owner_id: params[:owner_id]) if params[:owner_id].present?
    records
  end
end
