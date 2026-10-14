class FollowUpDeadline
  FIRST_CONTACT_WINDOW = 24.hours
  WARNING_WINDOW = 4.hours
  def self.deadline(created_at) = created_at + FIRST_CONTACT_WINDOW
  # Exactly at deadline is on time; strictly after is overdue.
  def self.overdue?(lead, now: Time.current)
    lead.first_contact_at.nil? && lead.first_contact_deadline < now
  end
  def self.remaining(lead, now: Time.current) = lead.first_contact_deadline - now
end
