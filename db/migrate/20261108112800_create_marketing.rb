class CreateMarketing < ActiveRecord::Migration[8.0]
  def change
    create_table :occasions do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :tagline
      t.text :description
      t.string :emoji
      t.string :theme, null: false, default: "saffron"
      t.date :season_starts_on
      t.date :season_ends_on
      t.bigint :from_price_paise
      t.jsonb :highlights, null: false, default: []
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :occasions, :slug, unique: true

    create_table :leads do |t|
      t.string :name, null: false
      t.string :work_email, null: false
      t.string :phone, null: false
      t.string :company_name, null: false
      t.integer :employee_count
      t.references :occasion, foreign_key: true
      t.bigint :budget_per_employee_paise
      t.text :message
      t.boolean :consent, null: false, default: false
      t.string :status, null: false, default: "fresh"
      t.text :lost_reason
      t.references :owner, foreign_key: { to_table: :users }
      t.date :follow_up_on
      t.string :source, null: false, default: "website"
      t.string :ip_address
      t.string :user_agent
      t.references :company, foreign_key: true
      t.datetime :converted_at
      t.timestamps
    end
    add_index :leads, :status
    add_index :leads, :follow_up_on
    add_index :leads, :work_email

    create_table :lead_activities do |t|
      t.references :lead, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :kind, null: false
      t.text :body
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind
      t.string :title, null: false
      t.text :body
      t.string :url
      t.datetime :read_at
      t.timestamps
    end
    add_index :notifications, [ :user_id, :read_at ]

    create_table :settings do |t|
      t.string :key, null: false
      t.jsonb :value
      t.timestamps
    end
    add_index :settings, :key, unique: true

    create_table :faqs do |t|
      t.string :question, null: false
      t.text :answer, null: false
      t.string :audience, null: false, default: "public"
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :legal_pages do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.text :summary
      t.text :body, null: false
      t.date :effective_on
      t.boolean :published, null: false, default: true
      t.timestamps
    end
    add_index :legal_pages, :slug, unique: true
  end
end
