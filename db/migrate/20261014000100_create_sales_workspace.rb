class CreateSalesWorkspace < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.timestamps
    end
    create_table :users do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "salesperson"
      t.string :time_zone, null: false, default: "Europe/Istanbul"
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_check_constraint :users, "role IN ('manager','salesperson')", name: "user_role"
    create_table :companies do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :industry
      t.timestamps
    end
    create_table :contacts do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.timestamps
    end
    create_table :leads do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.references :company, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.string :title, null: false
      t.string :status, null: false, default: "new"
      t.datetime :first_contact_deadline, null: false
      t.datetime :first_contact_at
      t.text :notes
      t.timestamps
    end
    add_index :leads, [:organization_id, :status, :first_contact_deadline]
    add_check_constraint :leads, "status IN ('new','contacted','qualified','converted','disqualified')", name: "lead_status"
    create_table :opportunities do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.references :company, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :lead, null: false, foreign_key: true, index: { unique: true }
      t.string :title, null: false
      t.string :status, null: false, default: "qualification"
      t.decimal :value, precision: 14, scale: 2, null: false, default: 0
      t.string :currency, null: false, default: "USD"
      t.date :expected_closing_date, null: false
      t.datetime :last_activity_at, null: false
      t.datetime :closed_at
      t.timestamps
    end
    add_index :opportunities, [:organization_id, :status]
    add_check_constraint :opportunities, "status IN ('qualification','proposal','negotiation','won','lost')", name: "opportunity_status"
    add_check_constraint :opportunities, "value >= 0 AND currency IN ('USD','EUR','TRY')", name: "opportunity_money"
    add_check_constraint :opportunities, "(status IN ('won','lost')) = (closed_at IS NOT NULL)", name: "opportunity_closure"
    create_table :activities do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :lead, foreign_key: true
      t.references :opportunity, foreign_key: true
      t.string :kind, null: false
      t.text :body, null: false
      t.datetime :completed_at, null: false
      t.timestamps
    end
    add_check_constraint :activities, "(lead_id IS NOT NULL)::int + (opportunity_id IS NOT NULL)::int = 1", name: "activity_parent"
    add_check_constraint :activities, "kind IN ('contact','note')", name: "activity_kind"
    create_table :tasks do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.references :lead, foreign_key: true
      t.references :opportunity, foreign_key: true
      t.string :title, null: false
      t.datetime :due_at, null: false
      t.datetime :completed_at
      t.timestamps
    end
    add_check_constraint :tasks, "(lead_id IS NOT NULL)::int + (opportunity_id IS NOT NULL)::int = 1", name: "task_parent"
    add_index :tasks, [:organization_id, :completed_at, :due_at]
    create_table :audit_events do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :record_type, null: false
      t.bigint :record_id, null: false
      t.string :action, null: false
      t.jsonb :details, null: false, default: {}
      t.timestamps
    end
    add_index :audit_events, [:organization_id, :record_type, :record_id]
  end
end
