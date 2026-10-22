require Rails.root.join("lib/agent_inquiry_ingress")
Rails.application.config.middleware.insert_before Rails::Rack::Logger, AgentInquiryIngress
