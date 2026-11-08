class CreateCoreTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :legal_name, null: false
      t.string :display_name
      t.string :gstin
      t.string :pan
      t.string :state
      t.text :billing_address
      t.text :shipping_address
      t.string :payment_terms, null: false, default: "prepaid"
      t.decimal :markup_override_pct, precision: 5, scale: 2
      t.string :assignment_mode_override
      t.bigint :approval_limit_paise
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :companies, :gstin, unique: true, where: "gstin IS NOT NULL"

    create_table :vendors do |t|
      t.string :business_name, null: false
      t.string :legal_name
      t.string :gstin
      t.string :pan
      t.string :phone
      t.string :email
      t.string :status, null: false, default: "pending"
      t.text :rejection_reason
      t.timestamps
    end
    add_index :vendors, :status

    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :phone
      t.string :role, null: false
      t.references :company, foreign_key: true
      t.references :vendor, foreign_key: true
      t.datetime :email_verified_at
      t.datetime :last_sign_in_at
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :users, :email_address, unique: true
    add_index :users, :role
  end
end
