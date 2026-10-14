class DashboardController < ApplicationController
  def index
    leads, opportunities = scope(Lead), scope(Opportunity)
    @statistics = { total_leads: leads.count, new_leads: leads.where(status: "new").count,
      overdue_contacts: leads.overdue.count, overdue_follow_ups: scope(Task).overdue.count,
      active_opportunities: opportunities.active.count, won_opportunities: opportunities.where(status: "won").count }
    @pipeline_values = opportunities.active.group(:currency).sum(:value)
    @won_values = opportunities.where(status: "won").group(:currency).sum(:value)
    @stage_counts = opportunities.group(:status).count
    @recommendations = NextBestAction.new(current_user).call
    @recent = (leads.includes(:company).order(updated_at: :desc).limit(5).to_a + opportunities.includes(:company).order(updated_at: :desc).limit(5).to_a).sort_by(&:updated_at).reverse.first(6)
    @tasks = scope(Task).pending.includes(:lead, :opportunity, :owner).order(:due_at).limit(5)
  end
end
