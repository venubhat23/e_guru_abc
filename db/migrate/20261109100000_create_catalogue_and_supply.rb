class CreateCatalogueAndSupply < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.references :parent, foreign_key: { to_table: :categories }
      t.decimal :markup_override_pct, precision: 5, scale: 2
      t.boolean :food, null: false, default: false
      t.string :emoji
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :categories, :slug, unique: true

    create_table :products do |t|
      t.references :category, null: false, foreign_key: true
      t.string :sku, null: false
      t.string :name, null: false
      t.text :description
      t.string :hsn_code, null: false
      t.decimal :gst_rate, precision: 5, scale: 2, null: false, default: 18
      t.integer :volume_units, null: false, default: 1
      t.jsonb :variants, null: false, default: {}
      t.boolean :brandable, null: false, default: false
      t.decimal :markup_override_pct, precision: 5, scale: 2
      t.string :emoji
      t.string :review_status, null: false, default: "approved"
      t.references :proposed_by_vendor, foreign_key: { to_table: :vendors }
      t.text :review_note
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :products, :sku, unique: true
    add_index :products, :review_status

    create_table :packages do |t|
      t.references :occasion, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :min_qty, null: false, default: 25
      t.string :emoji
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :packages, :slug, unique: true

    create_table :package_items do |t|
      t.references :package, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end
    add_index :package_items, %i[package_id product_id], unique: true

    change_table :vendors, bulk: true do |t|
      t.string :fssai_number
      t.string :contact_name
      t.text :warehouse_address
      t.string :warehouse_city
      t.string :warehouse_state
      t.string :warehouse_pincode
      t.string :bank_account_name
      t.text :bank_account_number
      t.string :bank_ifsc
      t.decimal :rating, precision: 3, scale: 2, null: false, default: 4.0
      t.datetime :approved_at
      t.datetime :suspended_at
      t.text :suspension_reason
    end

    create_table :vendor_regions do |t|
      t.references :vendor, null: false, foreign_key: true
      t.string :state, null: false
      t.string :city
      t.string :pincode_prefix
      t.timestamps
    end

    create_table :vendor_offers do |t|
      t.references :vendor, null: false, foreign_key: true
      t.references :offerable, polymorphic: true, null: false
      t.bigint :vendor_price_paise, null: false
      t.integer :moq, null: false, default: 1
      t.integer :capacity_per_week, null: false, default: 100
      t.integer :lead_time_days, null: false, default: 7
      t.integer :advance_pct, null: false, default: 0
      t.string :balance_terms, null: false, default: "on_delivery"
      t.integer :credit_days, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :vendor_offers, %i[vendor_id offerable_type offerable_id], unique: true, name: "index_vendor_offers_unique"
    add_check_constraint :vendor_offers, "advance_pct BETWEEN 0 AND 100", name: "advance_pct_range"
    add_check_constraint :vendor_offers, "vendor_price_paise > 0", name: "vendor_price_positive"

    create_table :employees do |t|
      t.references :company, null: false, foreign_key: true
      t.string :emp_code, null: false
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :department
      t.string :designation
      t.string :location
      t.text :address
      t.string :city
      t.string :pincode
      t.string :state
      t.date :dob
      t.date :joining_date
      t.string :tshirt_size
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :employees, %i[company_id emp_code], unique: true
  end
end
