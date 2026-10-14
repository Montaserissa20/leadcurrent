class NextBestAction
  INACTIVITY_WINDOW = 72.hours
  CLOSING_WINDOW = 7.days
  Recommendation = Data.define(:record, :priority, :reason, :action)
  def initialize(user, now: Time.current)
    @user, @now = user, now
  end
  def call
    leads = WorkspaceAccess.scope(@user, Lead).where(owner_id: editable_owners).awaiting_contact.where.not(status: %w[converted disqualified]).includes(:company, :owner)
    entries = leads.map do |lead|
      seconds = FollowUpDeadline.remaining(lead, now: @now)
      if seconds < 0
        Recommendation.new(record: lead, priority: 100, reason: "First contact overdue by #{hours(-seconds)} hours", action: :contact)
      elsif seconds <= FollowUpDeadline::WARNING_WINDOW
        Recommendation.new(record: lead, priority: 90, reason: "First contact deadline in #{hours(seconds)} hours", action: :contact)
      else
        Recommendation.new(record: lead, priority: 50, reason: "First contact due in #{hours(seconds)} hours", action: :contact)
      end
    end
    WorkspaceAccess.scope(@user, Opportunity).where(owner_id: editable_owners).active.includes(:company, :owner).each do |deal|
      pending = deal.tasks.pending.exists?
      if !pending && deal.last_activity_at <= @now - INACTIVITY_WINDOW
        entries << Recommendation.new(record: deal, priority: 80, reason: "No activity for #{hours(@now - deal.last_activity_at)} hours", action: :follow_up)
      elsif !pending && deal.expected_closing_date <= @now.to_date + CLOSING_WINDOW.in_days
        entries << Recommendation.new(record: deal, priority: 70, reason: "Expected close #{deal.expected_closing_date}; review next stage", action: :advance)
      end
    end
    entries.sort_by { |entry| [-entry.priority, entry.record.is_a?(Lead) ? entry.record.first_contact_deadline.to_f : entry.record.expected_closing_date.jd, entry.record.id] }.first(8)
  end
  private
  def editable_owners = @user.manager? ? @user.organization.users.select(:id) : [@user.id]
  def hours(seconds) = (seconds / 3600.0).round(1)
end
