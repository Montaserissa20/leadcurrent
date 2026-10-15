class NextBestAction
  INACTIVITY_WINDOW = 72.hours
  CLOSING_WINDOW = 7.days
  PRIORITIES = { overdue_contact: 100, overdue_task: 95, contact_warning: 90, today_task: 85, inactive: 80, closing: 70, new_contact: 50 }.freeze
  Recommendation = Data.define(:record, :priority, :reason, :action, :task) do
    def initialize(record:, priority:, reason:, action:, task: nil)
      super
    end
  end
  def initialize(user, now: Time.current)
    @user, @now = user, now.in_time_zone(user.time_zone)
  end
  def call(record: nil, limit: 8)
    leads = WorkspaceAccess.scope(@user, Lead).where(owner_id: editable_owners).awaiting_contact.where.not(status: %w[converted disqualified]).includes(:company, :owner)
    leads = record.is_a?(Lead) ? leads.where(id: record.id) : leads.none if record
    leads = leads.order(:first_contact_deadline, :id).limit(limit)
    entries = leads.map do |lead|
      seconds = FollowUpDeadline.remaining(lead, now: @now)
      if seconds < 0
        Recommendation.new(record: lead, priority: PRIORITIES[:overdue_contact], reason: "First contact overdue by #{hours(-seconds)} hours", action: :contact)
      elsif seconds <= FollowUpDeadline::WARNING_WINDOW
        Recommendation.new(record: lead, priority: PRIORITIES[:contact_warning], reason: "First contact deadline in #{hours(seconds)} hours", action: :contact)
      else
        Recommendation.new(record: lead, priority: PRIORITIES[:new_contact], reason: "First contact due in #{hours(seconds)} hours", action: :contact)
      end
    end
    deals = WorkspaceAccess.scope(@user, Opportunity).where(owner_id: editable_owners).active.includes(:company, :owner)
    deals = record.is_a?(Opportunity) ? deals.where(id: record.id) : deals.none if record
    pending_deals = WorkspaceAccess.scope(@user, Task).pending.where.not(opportunity_id: nil).select(:opportunity_id)
    deals = deals.where.not(id: pending_deals).where("last_activity_at <= ? OR expected_closing_date <= ?", @now - INACTIVITY_WINDOW, @now.to_date + CLOSING_WINDOW.in_days)
      .order(Arel.sql(Opportunity.sanitize_sql_array(["CASE WHEN last_activity_at <= ? THEN 0 ELSE 1 END", @now - INACTIVITY_WINDOW])), :expected_closing_date, :id).limit(limit)
    deals.each do |deal|
      if deal.last_activity_at <= @now - INACTIVITY_WINDOW
        entries << Recommendation.new(record: deal, priority: PRIORITIES[:inactive], reason: "No activity for #{hours(@now - deal.last_activity_at)} hours", action: :follow_up)
      elsif deal.expected_closing_date <= @now.to_date + CLOSING_WINDOW.in_days
        entries << Recommendation.new(record: deal, priority: PRIORITIES[:closing], reason: "Expected close #{deal.expected_closing_date}; review next stage", action: :advance)
      end
    end
    tasks = WorkspaceAccess.scope(@user, Task).pending.where(owner_id: editable_owners).where("due_at <= ?", @now.end_of_day).includes(lead: [:company, :owner], opportunity: [:company, :owner])
    tasks = tasks.where(record.is_a?(Lead) ? { lead_id: record.id } : { opportunity_id: record.id }) if record
    tasks = tasks.where(lead_id: WorkspaceAccess.scope(@user, Lead).where(owner_id: editable_owners).where.not(status: %w[converted disqualified]).select(:id))
      .or(tasks.where(opportunity_id: WorkspaceAccess.scope(@user, Opportunity).where(owner_id: editable_owners).active.select(:id)))
    tasks.order(:due_at, :id).limit(limit).each do |task|
      target = task.record
      next if target.is_a?(Lead) ? target.status.in?(%w[converted disqualified]) : target.terminal?
      overdue = task.due_at < @now
      entries << Recommendation.new(record: target, task: task, priority: PRIORITIES[overdue ? :overdue_task : :today_task], reason: overdue ? "Follow-up overdue by #{hours(@now - task.due_at)} hours" : "Follow-up due today at #{task.due_at.in_time_zone(@user.time_zone).strftime('%H:%M')}", action: :complete_task)
    end
    entries.sort_by { |entry| [-entry.priority, entry.task ? entry.task.due_at.to_f : entry.record.is_a?(Lead) ? entry.record.first_contact_deadline.to_f : entry.record.expected_closing_date.to_time.to_f, entry.record.id] }
      .uniq { |entry| [entry.record.class.name, entry.record.id] }.first(limit)
  end
  private
  def editable_owners = @user.manager? ? @user.organization.users.select(:id) : [@user.id]
  def hours(seconds) = (seconds / 3600.0).round(1)
end
