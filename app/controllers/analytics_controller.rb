class AnalyticsController < ApplicationController
  def index
    @metrics = SalesMetrics.new(current_user)
  end
end
