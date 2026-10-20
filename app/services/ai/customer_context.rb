module Ai
  class CustomerContext
    ACTIVITY_LIMIT = 6
    TASK_LIMIT = 5
    attr_reader :record, :facts, :recommendation, :activity_count, :generated_at

    def initialize(user, record)
      raise ActiveRecord::RecordNotFound unless [Lead, Opportunity].include?(record.class)
      @record = WorkspaceAccess.scope(user, record.class).find(record.id)
      company = WorkspaceAccess.scope(user, Company).find(@record.company_id)
      @generated_at = Time.current
      @recommendation = NextBestAction.new(user, now: generated_at).call(record: @record, limit: 1).first
      @facts = {
        "customer" => "Company: #{text(company.name, 100)}; industry: #{text(company.industry.presence || 'not recorded', 80)}",
        "record" => "#{@record.class.name}: #{text(@record.title, 120)}; status: #{@record.status}"
      }
      original = @record.is_a?(Opportunity) ? WorkspaceAccess.scope(user, Lead).where(company_id: @record.company_id, contact_id: @record.contact_id).find(@record.lead_id) : @record
      @facts["lead_notes"] = text(original.notes, 500) if original.notes.present?
      if @record.is_a?(Lead)
        @facts["deadline"] = "First-contact deadline: #{@record.first_contact_deadline.iso8601}; first contact: #{@record.first_contact_at&.iso8601 || 'not recorded'}"
      else
        @facts["deal"] = "Deal value (not a confirmed budget): #{@record.value.to_s('F')} #{@record.currency}; expected close: #{@record.expected_closing_date}; last activity: #{@record.last_activity_at.iso8601}; closed: #{@record.closed_at&.iso8601 || 'no'}"
      end
      activities = WorkspaceAccess.scope(user, Activity).where(lead_id: original.id)
      activities = activities.or(WorkspaceAccess.scope(user, Activity).where(opportunity_id: @record.id)) if @record.is_a?(Opportunity)
      @activity_count = activities.count
      activities.order(completed_at: :desc, id: :desc).limit(ACTIVITY_LIMIT).each_with_index do |activity, index|
        @facts["activity_#{index + 1}"] = "#{activity.completed_at.iso8601} #{activity.kind}: #{text(activity.body, 200)}"
      end
      @facts["history"] = activity_count.zero? ? "No recorded activity history for this customer." : "#{activity_count} recorded activities; only the latest #{ACTIVITY_LIMIT} at most are included."
      tasks = WorkspaceAccess.scope(user, Task).pending.where(@record.is_a?(Lead) ? { lead_id: @record.id } : { opportunity_id: @record.id })
      tasks.order(:due_at, :id).limit(TASK_LIMIT).each_with_index do |task, index|
        @facts["task_#{index + 1}"] = "Pending task due #{task.due_at.iso8601}: #{text(task.title, 100)}"
      end
    end

    def as_json
      { as_of: generated_at.iso8601, facts: facts, official_rule: recommendation && {
        priority: recommendation.priority, action: recommendation.action, reason: recommendation.reason
      }, boundaries: "24h first contact, <=4h warning, >=72h opportunity inactivity. Won/Lost and Converted/Disqualified are terminal." }
    end

    private
    def text(value, limit) = SafeText.call(value, limit: limit)
  end
end
