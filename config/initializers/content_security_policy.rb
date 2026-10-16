Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src :self
  policy.img_src :self, :data
  policy.script_src :self
  policy.style_src :self
  policy.object_src :none
  policy.base_uri :self
  policy.frame_ancestors :none
end
Rails.application.config.content_security_policy_nonce_generator = ->(request) { request.session[:content_security_policy_nonce] ||= SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = %w[script-src style-src]
