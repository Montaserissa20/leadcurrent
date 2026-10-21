module PageAgentHelper
  def page_agent_available?
    current_user && !current_user.password_change_required? && request.path.match?(%r{\A(?:/|/(?:leads|opportunities|tasks|analytics|pipeline|activity)|/(?:leads|opportunities)/\d+)\z})
  end
end
