class CreateBookingsAndFinance < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.string :number
      t.references :company, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :occasion, foreign_key: true
      t.references :bookable, polymorphic: true, null: false
      t.integer :quantity, null: false
      t.string :status, null: false, default: "draft"
      t.string :delivery_mode, null: false, default: "individual"
      t.date :requested_delivery_on, null: false
      t.string :place_of_supply_state, null: false
      t.string :assignment_mode, null: false, default: "auto"
      t.jsonb :personalisation, null: false, default: {}
      t.decimal :gst_rate, precision: 5, scale: 2, null: false, default: 18
      t.bigint :unit_price_paise, null: false, default: 0
      t.bigint :hr_subtotal_paise, null: false, default: 0
      t.bigint :delivery_charge_paise, null: false, default: 0
      t.bigint :cgst_paise, null: false, default: 0
      t.bigint :sgst_paise, null: false, default: 0
      t.bigint :igst_paise, null: false, default: 0
      t.bigint :total_paise, null: false, default: 0
      t.bigint :vendor_subtotal_paise, null: false, default: 0
      t.datetime :submitted_at
      t.datetime :paid_at
      t.datetime :confirmed_at
      t.datetime :delivered_at
      t.datetime :completed_at
      t.datetime :cancelled_at
      t.text :cancel_reason
      t.text :dispute_reason
      t.timestamps
    end
    add_index :bookings, :number, unique: true
    add_index :bookings, :status

    create_table :assignments do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :vendor, null: false, foreign_key: true
      t.references :vendor_offer, null: false, foreign_key: true
      t.string :status, null: false, default: "offered"
      t.integer :quantity, null: false
      t.bigint :vendor_unit_price_paise, null: false
      t.bigint :vendor_total_paise, null: false
      t.integer :advance_pct, null: false, default: 0
      t.string :balance_terms, null: false, default: "on_delivery"
      t.integer :credit_days, null: false, default: 0
      t.string :mode, null: false, default: "auto"
      t.datetime :expires_at
      t.datetime :accepted_at
      t.datetime :dispatched_at
      t.datetime :delivered_at
      t.text :rejection_reason
      t.text :problem_report
      t.timestamps
    end
    add_index :assignments, :status

    create_table :booking_recipients do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :employee, foreign_key: true
      t.references :assignment, foreign_key: true
      t.string :name, null: false
      t.string :phone
      t.text :address
      t.string :city
      t.string :state, null: false
      t.string :pincode, null: false
      t.string :tshirt_size
      t.string :card_message
      t.string :status, null: false, default: "pending"
      t.string :courier
      t.string :awb
      t.datetime :dispatched_at
      t.datetime :delivered_at
      t.timestamps
    end
    add_index :booking_recipients, :status

    create_table :capacity_reservations do |t|
      t.references :vendor_offer, null: false, foreign_key: true
      t.references :assignment, null: false, foreign_key: true, index: { unique: true }
      t.date :week_start, null: false
      t.integer :quantity, null: false
      t.timestamps
    end
    add_index :capacity_reservations, %i[vendor_offer_id week_start]

    create_table :payments do |t|
      t.references :booking, null: false, foreign_key: true
      t.string :method, null: false
      t.string :status, null: false, default: "pending"
      t.bigint :amount_paise, null: false
      t.bigint :gateway_fee_paise, null: false, default: 0
      t.string :razorpay_order_id
      t.string :razorpay_payment_id
      t.string :reference
      t.references :verified_by, foreign_key: { to_table: :users }
      t.datetime :verified_at
      t.text :notes
      t.timestamps
    end
    add_index :payments, :razorpay_order_id, unique: true, where: "razorpay_order_id IS NOT NULL"
    add_index :payments, :razorpay_payment_id, unique: true, where: "razorpay_payment_id IS NOT NULL"

    create_table :webhook_events do |t|
      t.string :provider, null: false
      t.string :event_id, null: false
      t.string :event_type
      t.jsonb :payload, null: false, default: {}
      t.datetime :processed_at
      t.timestamps
    end
    add_index :webhook_events, %i[provider event_id], unique: true

    create_table :vendor_payouts do |t|
      t.references :vendor, null: false, foreign_key: true
      t.references :assignment, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :status, null: false, default: "due"
      t.bigint :gross_paise, null: false
      t.bigint :penalty_paise, null: false, default: 0
      t.bigint :amount_paise, null: false
      t.date :due_on, null: false
      t.string :utr
      t.text :penalty_reason
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.datetime :paid_at
      t.datetime :received_at
      t.timestamps
    end
    add_index :vendor_payouts, %i[assignment_id kind], unique: true
    add_index :vendor_payouts, :status

    create_table :document_sequences do |t|
      t.string :kind, null: false
      t.string :financial_year, null: false
      t.integer :last_number, null: false, default: 0
      t.timestamps
    end
    add_index :document_sequences, %i[kind financial_year], unique: true

    create_table :invoices do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.references :original_invoice, foreign_key: { to_table: :invoices }
      t.string :kind, null: false
      t.string :number, null: false
      t.string :financial_year, null: false
      t.date :issued_on, null: false
      t.bigint :taxable_paise, null: false
      t.bigint :cgst_paise, null: false, default: 0
      t.bigint :sgst_paise, null: false, default: 0
      t.bigint :igst_paise, null: false, default: 0
      t.bigint :total_paise, null: false
      t.text :reason
      t.timestamps
    end
    add_index :invoices, :number, unique: true

    create_table :ledger_entries do |t|
      t.references :booking, null: false, foreign_key: true
      t.string :account, null: false
      t.bigint :amount_paise, null: false
      t.string :memo
      t.datetime :posted_at, null: false
      t.timestamps
    end
    add_index :ledger_entries, %i[booking_id account], unique: true

    create_table :tickets do |t|
      t.string :number
      t.references :booking, null: false, foreign_key: true
      t.references :booking_recipient, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.references :raised_by, foreign_key: { to_table: :users }
      t.references :assignee, foreign_key: { to_table: :users }
      t.string :category, null: false, default: "other"
      t.string :priority, null: false, default: "normal"
      t.string :status, null: false, default: "open"
      t.string :subject, null: false
      t.text :description
      t.text :resolution
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :tickets, :status
    add_index :tickets, :number, unique: true

    create_table :ticket_comments do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.text :body, null: false
      t.boolean :internal, null: false, default: false
      t.timestamps
    end
  end
end
