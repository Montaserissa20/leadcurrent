module ApplicationHelper
  def status_badge(record)
    tag.span(record.status.humanize, class: "badge status-#{record.status}")
  end
  def money(value, currency = "USD") = number_to_currency(value, unit: { "USD" => "$", "EUR" => "€", "TRY" => "₺" }.fetch(currency), precision: 0)
  def deadline_text(lead)
    return "Contact completed #{l(lead.first_contact_at, format: :short)}" if lead.first_contact_at
    seconds = FollowUpDeadline.remaining(lead)
    "#{seconds < 0 ? 'Overdue by' : 'Due in'} #{(seconds.abs / 3600.0).round(1)}h"
  end
  def record_actions_path(record) = record.is_a?(Lead) ? transition_lead_path(record) : transition_opportunity_path(record)
  def next_stages(record) = (record.is_a?(Lead) ? LeadTransition : OpportunityTransition)::TRANSITIONS.fetch(record.status)
end
