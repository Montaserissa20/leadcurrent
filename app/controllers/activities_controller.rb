class ActivitiesController < ApplicationController
  def index
    @activities = scope(Activity).includes(:actor, :lead, :opportunity).order(completed_at: :desc).limit(100)
    @audit_events = scope(AuditEvent).includes(:actor).order(created_at: :desc).limit(30)
  end
end
