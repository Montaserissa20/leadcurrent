module Copilot
  class Outcome
    def self.authorize_page!(user,path)
      raise PageAgent::Error.new(:invalid_request) unless path.is_a?(String) && path.match?(%r{\A(?:/|/(?:leads|opportunities|tasks|analytics|pipeline|activity)|/(?:leads|opportunities)/\d+)\z})
      if (match=path.match(%r{\A/(leads|opportunities)/(\d+)\z}))
        return WorkspaceAccess.scope(user,match[1] == "leads" ? Lead : Opportunity).find(match[2])
      end
      nil
    end

    def self.verified?(user,plan,input)
      record = authorize_page!(user,input.fetch("page_path"))
      return false if input["execution_error"] == true
      query = input.fetch("page_query")
      return false unless query.is_a?(String) && query.bytesize <= 1_000
      params = Rack::Utils.parse_query(query.delete_prefix("?"))
      return false unless (params.keys-%w[q status owner_id attention commit]).empty?
      destination = plan["destination"]
      if destination == "record"
        return false unless record && plan["search"].present?
        company = WorkspaceAccess.scope(user,Company).find(record.company_id)
        matches = [record.title,company.name].any? { |text| text.downcase.include?(plan["search"].strip.downcase) }
        ActiveSupport::Notifications.instrument('verification.copilot',destination:'record',model_reported_success:input['agent_success'],goal_matches:matches)
        return matches
      elsif destination == "note"
        return false unless record && input["note_present"] == true
        WorkspaceAccess.authorize!(user,record)
        return true # The browser separately checks actual input/kind/date; the server cannot inspect unsaved DOM.
      end
      return false unless %w[leads opportunities tasks pipeline analytics activity].include?(destination) && input["page_path"] == "/#{destination}"
      return true unless %w[read_crm_data show_crm_data].include?(plan["intent"])
      expected = {"leads"=>"leads","overdue_leads"=>"leads","attention_leads"=>"leads","opportunities"=>"opportunities","pending_tasks"=>"tasks"}[plan["query"]]
      return false unless expected == destination && params.fetch("q","") == plan["search"]
      return false unless params.fetch("owner_id","") == (plan["audience"] == "mine" ? user.id.to_s : "")
      case plan["query"]
      when "leads" then params.fetch('attention','').empty? && params.fetch('status','') == (plan['status'] == 'any' ? '' : plan['status'])
      when "overdue_leads" then params["attention"] == "overdue" && params.fetch("status","").empty?
      when "attention_leads" then false # No existing UI filter exactly means 'due by end of today'. Never claim it does.
      when "opportunities" then params.fetch("status","") == (plan["status"] == "any" ? "" : plan["status"])
      when "pending_tasks" then params["status"] == (plan["period"] == "all" ? "pending" : plan["period"])
      else false
      end
    rescue WorkflowError, ArgumentError
      false
    end
  end
end
