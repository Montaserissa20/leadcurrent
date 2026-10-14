class HealthController < ActionController::Base
  def show
    ActiveRecord::Base.connection.select_value("SELECT 1")
    render json: { status: "ok", database: "connected" }
  rescue ActiveRecord::ConnectionNotEstablished, PG::Error
    render json: { status: "unavailable" }, status: :service_unavailable
  end
end
