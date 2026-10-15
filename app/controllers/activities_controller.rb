class ActivitiesController < ApplicationController
  def index
    records = scope(Activity)
    records = records.where(kind: params[:kind]) if params[:kind].in?(%w[contact note])
    records = records.where("body ILIKE ?", "%#{Activity.sanitize_sql_like(params[:q].to_s)}%") if params[:q].present?
    @activities = records.includes(:actor, :lead, :opportunity).order(completed_at: :desc, id: :desc).limit(100)
    @audit_events = scope(AuditEvent).includes(:actor).order(created_at: :desc).limit(30)
  end
end
