module AgentIntakeTestSupport
  def inquiry_payload(**overrides)
    { "company_name" => "Fictional Atlas Procurement", "contact_name" => "Fictional Alex Buyer", "contact_email" => "buyer@example.test",
      "product_or_service" => "Software subscriptions", "quantity" => 50, "currency" => "USD", "stated_budget" => 10000,
      "requirements" => "Team management and reporting", "desired_timeline" => "Within 30 days", "message" => "Please provide pricing; proposed budget is unverified." }.merge(overrides.stringify_keys)
  end
  def make_inquiry(user, **overrides)
    credential, _token = AgentCredential.issue!(actor: user, name: "Test purchasing agent")
    AgentIntake::Submit.call(credential: credential, payload: AgentIntake::Payload.new(inquiry_payload(**overrides)), idempotency_key: SecureRandom.hex(16)).first
  end
  def qualification_answer(status: "pending_review")
    { summary: "The requester claims to need 50 software subscriptions.", potential_opportunity: "A proposed USD budget and quantity are supplied, not independently verified.",
      missing_information: ["Buyer identity and purchasing authority remain unverified."], suggested_next_step: "A human should confirm requirements and authority before preparing a quotation.", evidence_fields: %w[quantity product_or_service stated_budget], human_review_status: status, claims_verified: false }
  end
end
