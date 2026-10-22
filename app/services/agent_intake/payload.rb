require "bigdecimal"
require "digest"
module AgentIntake
  class Payload
    FIELDS = %w[company_name contact_name contact_email product_or_service quantity currency stated_budget requirements desired_timeline message].freeze
    LENGTHS = { "company_name" => 150, "contact_name" => 150, "contact_email" => 254, "product_or_service" => 200, "currency" => 3, "requirements" => 3000, "desired_timeline" => 200, "message" => 2000 }.freeze
    CREDENTIAL = /(?:lc_agent_[a-f0-9]{24}\.[A-Za-z0-9_-]{43}|\b(?:gsk_|sk-|ghp_)[A-Za-z0-9_-]{20,}|-----BEGIN .*PRIVATE KEY-----)/
    attr_reader :original, :attributes, :digest
    def self.parse(body)
      new(JSON.parse(body, max_nesting: 8, allow_duplicate_key: false))
    rescue JSON::ParserError, EncodingError
      raise Error.new(:invalid_json)
    end
    def initialize(input)
      raise Error.new(:invalid_fields) unless input.is_a?(Hash) && (input.keys - FIELDS).empty?
      @original = JSON.parse(JSON.generate(input))
      @attributes = {}
      LENGTHS.each do |field, limit|
        value = input[field]
        raise Error.new(:invalid_fields) unless value.nil? || value.is_a?(String) && value.valid_encoding? && value.length <= limit && !value.match?(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/) && !value.match?(CREDENTIAL)
        @attributes[field] = value&.strip.presence
      end
      raise Error.new(:invalid_fields) unless %w[company_name product_or_service message].all? { |field| @attributes[field].present? }
      email = @attributes["contact_email"]
      raise Error.new(:invalid_fields) if email && !URI::MailTo::EMAIL_REGEXP.match?(email)
      quantity = input["quantity"]
      raise Error.new(:invalid_fields) unless quantity.nil? || quantity.is_a?(Integer) && quantity.between?(1, 1_000_000)
      @attributes["quantity"] = quantity
      currency = @attributes["currency"]
      raise Error.new(:invalid_fields) if currency && !%w[USD EUR TRY].include?(currency)
      budget = input["stated_budget"]
      unless budget.nil?
        valid_type = budget.is_a?(String) || budget.is_a?(Integer) || budget.is_a?(Float) && budget.finite?
        raise Error.new(:invalid_fields) unless valid_type && budget.to_s.match?(/\A\d{1,12}(?:\.\d{1,2})?\z/) && currency
        @attributes["stated_budget"] = BigDecimal(budget.to_s)
      end
      @digest = Digest::SHA256.hexdigest(JSON.generate(@original.sort.to_h))
    end
  end
end
