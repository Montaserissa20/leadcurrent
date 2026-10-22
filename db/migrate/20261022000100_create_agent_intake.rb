class CreateAgentIntake < ActiveRecord::Migration[8.1]
  def change
    add_index :users, [:organization_id, :id], unique: true, name: "users_workspace_identity"
    add_index :leads, [:organization_id, :id], unique: true, name: "leads_workspace_identity"

    create_table :agent_credentials do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :created_by, null: false
      t.string :name, null: false, limit: 80
      t.string :identifier, null: false, limit: 24
      t.string :token_digest, null: false, limit: 64
      t.string :scope, null: false, default: "inquiries:create"
      t.datetime :expires_at
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :agent_credentials, :identifier, unique: true
    add_index :agent_credentials, :token_digest, unique: true
    add_index :agent_credentials, [:organization_id, :id], unique: true, name: "agent_credentials_workspace_identity"
    add_foreign_key :agent_credentials, :users, column: [:organization_id, :created_by_id], primary_key: [:organization_id, :id], name: "agent_credential_issuer_workspace"
    add_check_constraint :agent_credentials, "scope = 'inquiries:create'", name: "agent_credential_scope"
    add_check_constraint :agent_credentials, "identifier ~ '^[a-f0-9]{24}$' AND token_digest ~ '^[a-f0-9]{64}$'", name: "agent_credential_digest_shape"

    create_table :agent_inquiries do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :agent_credential, null: false
      t.references :reviewed_by
      t.references :accepted_lead, index: { unique: true }
      t.string :company_name, null: false, limit: 150
      t.string :contact_name, limit: 150
      t.string :contact_email, limit: 254
      t.string :product_or_service, null: false, limit: 200
      t.integer :quantity
      t.string :currency, limit: 3
      t.decimal :stated_budget, precision: 14, scale: 2
      t.text :requirements
      t.string :desired_timeline, limit: 200
      t.text :message, null: false
      t.string :status, null: false, default: "pending_review"
      t.datetime :submitted_at, null: false
      t.datetime :reviewed_at
      t.string :review_reason, limit: 500
      t.string :idempotency_digest, null: false, limit: 64
      t.string :payload_digest, null: false, limit: 64
      t.jsonb :submitted_payload, null: false
      t.timestamps
    end
    add_index :agent_inquiries, [:agent_credential_id, :idempotency_digest], unique: true, name: "agent_inquiry_durable_idempotency"
    add_index :agent_inquiries, [:organization_id, :status, :submitted_at], name: "agent_inquiry_inbox"
    add_foreign_key :agent_inquiries, :agent_credentials, column: [:organization_id, :agent_credential_id], primary_key: [:organization_id, :id], name: "agent_inquiry_credential_workspace"
    add_foreign_key :agent_inquiries, :users, column: [:organization_id, :reviewed_by_id], primary_key: [:organization_id, :id], name: "agent_inquiry_reviewer_workspace"
    add_foreign_key :agent_inquiries, :leads, column: [:organization_id, :accepted_lead_id], primary_key: [:organization_id, :id], name: "agent_inquiry_lead_workspace"
    add_check_constraint :agent_inquiries, "status IN ('pending_review','needs_information','accepted','rejected')", name: "agent_inquiry_status"
    add_check_constraint :agent_inquiries, "(status = 'accepted') = (accepted_lead_id IS NOT NULL)", name: "agent_inquiry_acceptance"
    add_check_constraint :agent_inquiries, "(status = 'pending_review' AND reviewed_by_id IS NULL AND reviewed_at IS NULL) OR (status <> 'pending_review' AND reviewed_by_id IS NOT NULL AND reviewed_at IS NOT NULL)", name: "agent_inquiry_review_evidence"
    add_check_constraint :agent_inquiries, "quantity IS NULL OR quantity BETWEEN 1 AND 1000000", name: "agent_inquiry_quantity"
    add_check_constraint :agent_inquiries, "(currency IS NULL OR currency IN ('USD','EUR','TRY')) AND (stated_budget IS NULL OR (currency IS NOT NULL AND stated_budget BETWEEN 0 AND 999999999999.99))", name: "agent_inquiry_money"
    add_check_constraint :agent_inquiries, "char_length(company_name) BETWEEN 1 AND 150 AND char_length(product_or_service) BETWEEN 1 AND 200 AND char_length(message) BETWEEN 1 AND 2000 AND (requirements IS NULL OR char_length(requirements) <= 3000)", name: "agent_inquiry_text_bounds"
    add_check_constraint :agent_inquiries, "jsonb_typeof(submitted_payload) = 'object' AND idempotency_digest ~ '^[a-f0-9]{64}$' AND payload_digest ~ '^[a-f0-9]{64}$'", name: "agent_inquiry_receipt_shape"
  end
end
