# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :question, :ai_response, :agent_request, :messages, :tools, :agent_task, :message, :conversation_id, :run_id, :page_query, :api_key, :apiKey,
  :agent_credential, :authorization, :requirements, :company_name, :contact_name, :product_or_service, :desired_timeline, :stated_budget, :reason
]
