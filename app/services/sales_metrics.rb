class SalesMetrics
  attr_reader :statistics, :pipeline_values, :won_values, :stage_counts, :average_values, :stage_values

  def initialize(user)
    leads = WorkspaceAccess.scope(user, Lead)
    opportunities = WorkspaceAccess.scope(user, Opportunity)
    lead_counts = leads.group(:status).count
    @stage_counts = opportunities.group(:status).count
    total = lead_counts.values.sum
    converted = lead_counts.fetch("converted", 0)
    @statistics = {
      total_leads: total, new_leads: lead_counts.fetch("new", 0), converted_leads: converted,
      conversion_rate: total.zero? ? 0.0 : (converted.fdiv(total) * 100).round(1),
      overdue_contacts: leads.overdue.count,
      overdue_follow_ups: WorkspaceAccess.scope(user, Task).overdue.count,
      active_opportunities: @stage_counts.except("won", "lost").values.sum,
      won_opportunities: @stage_counts.fetch("won", 0), lost_opportunities: @stage_counts.fetch("lost", 0)
    }
    @pipeline_values = opportunities.active.group(:currency).sum(:value)
    @won_values = opportunities.where(status: "won").group(:currency).sum(:value)
    @average_values = opportunities.group(:currency).average(:value)
    @stage_values = opportunities.group(:status, :currency).sum(:value)
  end
end
