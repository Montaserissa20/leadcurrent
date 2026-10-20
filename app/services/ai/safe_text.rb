module Ai
  class SafeText
    def self.call(value, limit:)
      text = value.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      %w[GROQ_API_KEY SECRET_KEY_BASE RAILS_MASTER_KEY].each do |name|
        secret = ENV[name]
        text = text.gsub(secret, "[redacted credential]") if secret.present? && secret.bytesize >= 8
      end
      text = text.gsub(/\b(?:gsk_|sk-(?:proj-)?|ghp_)[A-Za-z0-9_-]{12,}\b/, "[redacted credential]")
        .gsub(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i, "[email omitted]")
        .gsub(/(?<!\w)(?:\+\d[\d ()-]{6,}\d|\d{3}[ ()-]\d{3}[ -]\d{4}|\d{10,15})(?!\w)/, "[phone omitted]")
        .gsub(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/, "")
      text.byteslice(0, limit).to_s.scrub("")
    end
  end
end
