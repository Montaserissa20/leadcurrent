class DashboardController < ApplicationController
  def index
    leads, opportunities = scope(Lead), scope(Opportunity)
    @metrics = SalesMetrics.new(current_user)
    @statistics, @pipeline_values, @won_values, @stage_counts = @metrics.statistics, @metrics.pipeline_values, @metrics.won_values, @metrics.stage_counts
    @recommendations = NextBestAction.new(current_user).call
    @recent = (leads.includes(:company).order(updated_at: :desc).limit(5).to_a + opportunities.includes(:company).order(updated_at: :desc).limit(5).to_a).sort_by(&:updated_at).reverse.first(6)
    @tasks = scope(Task).pending.includes(:lead, :opportunity, :owner).order(:due_at).limit(5)
    @today_count = scope(Task).pending.where(due_at: Time.current.beginning_of_day..Time.current.end_of_day).count
  end
end
