# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_22_000100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activities", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "actor_id", null: false
    t.bigint "lead_id"
    t.bigint "opportunity_id"
    t.string "kind", null: false
    t.text "body", null: false
    t.datetime "completed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_activities_on_actor_id"
    t.index ["lead_id"], name: "index_activities_on_lead_id"
    t.index ["opportunity_id"], name: "index_activities_on_opportunity_id"
    t.index ["organization_id"], name: "index_activities_on_organization_id"
    t.check_constraint "((lead_id IS NOT NULL)::integer + (opportunity_id IS NOT NULL)::integer) = 1", name: "activity_parent"
    t.check_constraint "kind::text = ANY (ARRAY['contact'::character varying, 'note'::character varying]::text[])", name: "activity_kind"
  end

  create_table "agent_credentials", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "created_by_id", null: false
    t.string "name", limit: 80, null: false
    t.string "identifier", limit: 24, null: false
    t.string "token_digest", limit: 64, null: false
    t.string "scope", default: "inquiries:create", null: false
    t.datetime "expires_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_agent_credentials_on_created_by_id"
    t.index ["identifier"], name: "index_agent_credentials_on_identifier", unique: true
    t.index ["organization_id", "id"], name: "agent_credentials_workspace_identity", unique: true
    t.index ["organization_id"], name: "index_agent_credentials_on_organization_id"
    t.index ["token_digest"], name: "index_agent_credentials_on_token_digest", unique: true
    t.check_constraint "identifier::text ~ '^[a-f0-9]{24}$'::text AND token_digest::text ~ '^[a-f0-9]{64}$'::text", name: "agent_credential_digest_shape"
    t.check_constraint "scope::text = 'inquiries:create'::text", name: "agent_credential_scope"
  end

  create_table "agent_inquiries", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "agent_credential_id", null: false
    t.bigint "reviewed_by_id"
    t.bigint "accepted_lead_id"
    t.string "company_name", limit: 150, null: false
    t.string "contact_name", limit: 150
    t.string "contact_email", limit: 254
    t.string "product_or_service", limit: 200, null: false
    t.integer "quantity"
    t.string "currency", limit: 3
    t.decimal "stated_budget", precision: 14, scale: 2
    t.text "requirements"
    t.string "desired_timeline", limit: 200
    t.text "message", null: false
    t.string "status", default: "pending_review", null: false
    t.datetime "submitted_at", null: false
    t.datetime "reviewed_at"
    t.string "review_reason", limit: 500
    t.string "idempotency_digest", limit: 64, null: false
    t.string "payload_digest", limit: 64, null: false
    t.jsonb "submitted_payload", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accepted_lead_id"], name: "index_agent_inquiries_on_accepted_lead_id", unique: true
    t.index ["agent_credential_id", "idempotency_digest"], name: "agent_inquiry_durable_idempotency", unique: true
    t.index ["agent_credential_id"], name: "index_agent_inquiries_on_agent_credential_id"
    t.index ["organization_id", "status", "submitted_at"], name: "agent_inquiry_inbox"
    t.index ["organization_id"], name: "index_agent_inquiries_on_organization_id"
    t.index ["reviewed_by_id"], name: "index_agent_inquiries_on_reviewed_by_id"
    t.check_constraint "(currency IS NULL OR (currency::text = ANY (ARRAY['USD'::character varying, 'EUR'::character varying, 'TRY'::character varying]::text[]))) AND (stated_budget IS NULL OR currency IS NOT NULL AND stated_budget >= 0::numeric AND stated_budget <= 999999999999.99)", name: "agent_inquiry_money"
    t.check_constraint "(status::text = 'accepted'::text) = (accepted_lead_id IS NOT NULL)", name: "agent_inquiry_acceptance"
    t.check_constraint "char_length(company_name::text) >= 1 AND char_length(company_name::text) <= 150 AND char_length(product_or_service::text) >= 1 AND char_length(product_or_service::text) <= 200 AND char_length(message) >= 1 AND char_length(message) <= 2000 AND (requirements IS NULL OR char_length(requirements) <= 3000)", name: "agent_inquiry_text_bounds"
    t.check_constraint "jsonb_typeof(submitted_payload) = 'object'::text AND idempotency_digest::text ~ '^[a-f0-9]{64}$'::text AND payload_digest::text ~ '^[a-f0-9]{64}$'::text", name: "agent_inquiry_receipt_shape"
    t.check_constraint "quantity IS NULL OR quantity >= 1 AND quantity <= 1000000", name: "agent_inquiry_quantity"
    t.check_constraint "status::text = 'pending_review'::text AND reviewed_by_id IS NULL AND reviewed_at IS NULL OR status::text <> 'pending_review'::text AND reviewed_by_id IS NOT NULL AND reviewed_at IS NOT NULL", name: "agent_inquiry_review_evidence"
    t.check_constraint "status::text = ANY (ARRAY['pending_review'::character varying, 'needs_information'::character varying, 'accepted'::character varying, 'rejected'::character varying]::text[])", name: "agent_inquiry_status"
  end

  create_table "audit_events", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "actor_id", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.string "action", null: false
    t.jsonb "details", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_audit_events_on_actor_id"
    t.index ["organization_id", "record_type", "record_id"], name: "idx_on_organization_id_record_type_record_id_3081173603"
    t.index ["organization_id"], name: "index_audit_events_on_organization_id"
  end

  create_table "companies", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.string "industry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_companies_on_organization_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "company_id", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_contacts_on_company_id"
    t.index ["organization_id"], name: "index_contacts_on_organization_id"
  end

  create_table "leads", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "owner_id", null: false
    t.bigint "company_id", null: false
    t.bigint "contact_id", null: false
    t.string "title", null: false
    t.string "status", default: "new", null: false
    t.datetime "first_contact_deadline", null: false
    t.datetime "first_contact_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_leads_on_company_id"
    t.index ["contact_id"], name: "index_leads_on_contact_id"
    t.index ["organization_id", "id"], name: "leads_workspace_identity", unique: true
    t.index ["organization_id", "status", "first_contact_deadline"], name: "idx_on_organization_id_status_first_contact_deadlin_95a370b813"
    t.index ["organization_id"], name: "index_leads_on_organization_id"
    t.index ["owner_id"], name: "index_leads_on_owner_id"
    t.check_constraint "status::text = ANY (ARRAY['new'::character varying, 'contacted'::character varying, 'qualified'::character varying, 'converted'::character varying, 'disqualified'::character varying]::text[])", name: "lead_status"
  end

  create_table "opportunities", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "owner_id", null: false
    t.bigint "company_id", null: false
    t.bigint "contact_id", null: false
    t.bigint "lead_id", null: false
    t.string "title", null: false
    t.string "status", default: "qualification", null: false
    t.decimal "value", precision: 14, scale: 2, default: "0.0", null: false
    t.string "currency", default: "USD", null: false
    t.date "expected_closing_date", null: false
    t.datetime "last_activity_at", null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_opportunities_on_company_id"
    t.index ["contact_id"], name: "index_opportunities_on_contact_id"
    t.index ["lead_id"], name: "index_opportunities_on_lead_id", unique: true
    t.index ["organization_id", "status"], name: "index_opportunities_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_opportunities_on_organization_id"
    t.index ["owner_id"], name: "index_opportunities_on_owner_id"
    t.check_constraint "(status::text = ANY (ARRAY['won'::character varying, 'lost'::character varying]::text[])) = (closed_at IS NOT NULL)", name: "opportunity_closure"
    t.check_constraint "status::text = ANY (ARRAY['qualification'::character varying, 'proposal'::character varying, 'negotiation'::character varying, 'won'::character varying, 'lost'::character varying]::text[])", name: "opportunity_status"
    t.check_constraint "value >= 0::numeric AND (currency::text = ANY (ARRAY['USD'::character varying, 'EUR'::character varying, 'TRY'::character varying]::text[]))", name: "opportunity_money"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "owner_id", null: false
    t.bigint "lead_id"
    t.bigint "opportunity_id"
    t.string "title", null: false
    t.datetime "due_at", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lead_id"], name: "index_tasks_on_lead_id"
    t.index ["opportunity_id"], name: "index_tasks_on_opportunity_id"
    t.index ["organization_id", "completed_at", "due_at"], name: "index_tasks_on_organization_id_and_completed_at_and_due_at"
    t.index ["organization_id"], name: "index_tasks_on_organization_id"
    t.index ["owner_id"], name: "index_tasks_on_owner_id"
    t.check_constraint "((lead_id IS NOT NULL)::integer + (opportunity_id IS NOT NULL)::integer) = 1", name: "task_parent"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "salesperson", null: false
    t.string "time_zone", default: "Europe/Istanbul", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "password_change_required", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id", "id"], name: "users_workspace_identity", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.check_constraint "role::text = ANY (ARRAY['manager'::character varying, 'salesperson'::character varying]::text[])", name: "user_role"
  end

  add_foreign_key "activities", "leads"
  add_foreign_key "activities", "opportunities"
  add_foreign_key "activities", "organizations"
  add_foreign_key "activities", "users", column: "actor_id"
  add_foreign_key "agent_credentials", "organizations"
  add_foreign_key "agent_credentials", "users", column: ["organization_id", "created_by_id"], primary_key: ["organization_id", "id"], name: "agent_credential_issuer_workspace"
  add_foreign_key "agent_inquiries", "agent_credentials", column: ["organization_id", "agent_credential_id"], primary_key: ["organization_id", "id"], name: "agent_inquiry_credential_workspace"
  add_foreign_key "agent_inquiries", "leads", column: ["organization_id", "accepted_lead_id"], primary_key: ["organization_id", "id"], name: "agent_inquiry_lead_workspace"
  add_foreign_key "agent_inquiries", "organizations"
  add_foreign_key "agent_inquiries", "users", column: ["organization_id", "reviewed_by_id"], primary_key: ["organization_id", "id"], name: "agent_inquiry_reviewer_workspace"
  add_foreign_key "audit_events", "organizations"
  add_foreign_key "audit_events", "users", column: "actor_id"
  add_foreign_key "companies", "organizations"
  add_foreign_key "contacts", "companies"
  add_foreign_key "contacts", "organizations"
  add_foreign_key "leads", "companies"
  add_foreign_key "leads", "contacts"
  add_foreign_key "leads", "organizations"
  add_foreign_key "leads", "users", column: "owner_id"
  add_foreign_key "opportunities", "companies"
  add_foreign_key "opportunities", "contacts"
  add_foreign_key "opportunities", "leads"
  add_foreign_key "opportunities", "organizations"
  add_foreign_key "opportunities", "users", column: "owner_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "tasks", "leads"
  add_foreign_key "tasks", "opportunities"
  add_foreign_key "tasks", "organizations"
  add_foreign_key "tasks", "users", column: "owner_id"
  add_foreign_key "users", "organizations"
end
