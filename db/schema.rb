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

ActiveRecord::Schema[8.1].define(version: 2026_11_09_110000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assignments", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "vendor_id", null: false
    t.bigint "vendor_offer_id", null: false
    t.string "status", default: "offered", null: false
    t.integer "quantity", null: false
    t.bigint "vendor_unit_price_paise", null: false
    t.bigint "vendor_total_paise", null: false
    t.integer "advance_pct", default: 0, null: false
    t.string "balance_terms", default: "on_delivery", null: false
    t.integer "credit_days", default: 0, null: false
    t.string "mode", default: "auto", null: false
    t.datetime "expires_at"
    t.datetime "accepted_at"
    t.datetime "dispatched_at"
    t.datetime "delivered_at"
    t.text "rejection_reason"
    t.text "problem_report"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_assignments_on_booking_id"
    t.index ["status"], name: "index_assignments_on_status"
    t.index ["vendor_id"], name: "index_assignments_on_vendor_id"
    t.index ["vendor_offer_id"], name: "index_assignments_on_vendor_offer_id"
  end

  create_table "booking_recipients", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "employee_id"
    t.bigint "assignment_id"
    t.string "name", null: false
    t.string "phone"
    t.text "address"
    t.string "city"
    t.string "state", null: false
    t.string "pincode", null: false
    t.string "tshirt_size"
    t.string "card_message"
    t.string "status", default: "pending", null: false
    t.string "courier"
    t.string "awb"
    t.datetime "dispatched_at"
    t.datetime "delivered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_booking_recipients_on_assignment_id"
    t.index ["booking_id"], name: "index_booking_recipients_on_booking_id"
    t.index ["employee_id"], name: "index_booking_recipients_on_employee_id"
    t.index ["status"], name: "index_booking_recipients_on_status"
  end

  create_table "bookings", force: :cascade do |t|
    t.string "number"
    t.bigint "company_id", null: false
    t.bigint "created_by_id"
    t.bigint "occasion_id"
    t.string "bookable_type", null: false
    t.bigint "bookable_id", null: false
    t.integer "quantity", null: false
    t.string "status", default: "draft", null: false
    t.string "delivery_mode", default: "individual", null: false
    t.date "requested_delivery_on", null: false
    t.string "place_of_supply_state", null: false
    t.string "assignment_mode", default: "auto", null: false
    t.jsonb "personalisation", default: {}, null: false
    t.decimal "gst_rate", precision: 5, scale: 2, default: "18.0", null: false
    t.bigint "unit_price_paise", default: 0, null: false
    t.bigint "hr_subtotal_paise", default: 0, null: false
    t.bigint "delivery_charge_paise", default: 0, null: false
    t.bigint "cgst_paise", default: 0, null: false
    t.bigint "sgst_paise", default: 0, null: false
    t.bigint "igst_paise", default: 0, null: false
    t.bigint "total_paise", default: 0, null: false
    t.bigint "vendor_subtotal_paise", default: 0, null: false
    t.datetime "submitted_at"
    t.datetime "paid_at"
    t.datetime "confirmed_at"
    t.datetime "delivered_at"
    t.datetime "completed_at"
    t.datetime "cancelled_at"
    t.text "cancel_reason"
    t.text "dispute_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bookable_type", "bookable_id"], name: "index_bookings_on_bookable"
    t.index ["company_id"], name: "index_bookings_on_company_id"
    t.index ["created_by_id"], name: "index_bookings_on_created_by_id"
    t.index ["number"], name: "index_bookings_on_number", unique: true
    t.index ["occasion_id"], name: "index_bookings_on_occasion_id"
    t.index ["status"], name: "index_bookings_on_status"
  end

  create_table "capacity_reservations", force: :cascade do |t|
    t.bigint "vendor_offer_id", null: false
    t.bigint "assignment_id", null: false
    t.date "week_start", null: false
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_capacity_reservations_on_assignment_id", unique: true
    t.index ["vendor_offer_id", "week_start"], name: "index_capacity_reservations_on_vendor_offer_id_and_week_start"
    t.index ["vendor_offer_id"], name: "index_capacity_reservations_on_vendor_offer_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.bigint "parent_id"
    t.decimal "markup_override_pct", precision: 5, scale: 2
    t.boolean "food", default: false, null: false
    t.string "emoji"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "companies", force: :cascade do |t|
    t.string "legal_name", null: false
    t.string "display_name"
    t.string "gstin"
    t.string "pan"
    t.string "state"
    t.text "billing_address"
    t.text "shipping_address"
    t.string "payment_terms", default: "prepaid", null: false
    t.decimal "markup_override_pct", precision: 5, scale: 2
    t.string "assignment_mode_override"
    t.bigint "approval_limit_paise"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gstin"], name: "index_companies_on_gstin", unique: true, where: "(gstin IS NOT NULL)"
  end

  create_table "document_sequences", force: :cascade do |t|
    t.string "kind", null: false
    t.string "financial_year", null: false
    t.integer "last_number", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind", "financial_year"], name: "index_document_sequences_on_kind_and_financial_year", unique: true
  end

  create_table "employees", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "emp_code", null: false
    t.string "name", null: false
    t.string "email"
    t.string "phone"
    t.string "department"
    t.string "designation"
    t.string "location"
    t.text "address"
    t.string "city"
    t.string "pincode"
    t.string "state"
    t.date "dob"
    t.date "joining_date"
    t.string "tshirt_size"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "emp_code"], name: "index_employees_on_company_id_and_emp_code", unique: true
    t.index ["company_id"], name: "index_employees_on_company_id"
  end

  create_table "faqs", force: :cascade do |t|
    t.string "question", null: false
    t.text "answer", null: false
    t.string "audience", default: "public", null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "company_id", null: false
    t.bigint "original_invoice_id"
    t.string "kind", null: false
    t.string "number", null: false
    t.string "financial_year", null: false
    t.date "issued_on", null: false
    t.bigint "taxable_paise", null: false
    t.bigint "cgst_paise", default: 0, null: false
    t.bigint "sgst_paise", default: 0, null: false
    t.bigint "igst_paise", default: 0, null: false
    t.bigint "total_paise", null: false
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_invoices_on_booking_id"
    t.index ["company_id"], name: "index_invoices_on_company_id"
    t.index ["number"], name: "index_invoices_on_number", unique: true
    t.index ["original_invoice_id"], name: "index_invoices_on_original_invoice_id"
  end

  create_table "lead_activities", force: :cascade do |t|
    t.bigint "lead_id", null: false
    t.bigint "user_id"
    t.string "kind", null: false
    t.text "body"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lead_id"], name: "index_lead_activities_on_lead_id"
    t.index ["user_id"], name: "index_lead_activities_on_user_id"
  end

  create_table "leads", force: :cascade do |t|
    t.string "name", null: false
    t.string "work_email", null: false
    t.string "phone", null: false
    t.string "company_name", null: false
    t.integer "employee_count"
    t.bigint "occasion_id"
    t.bigint "budget_per_employee_paise"
    t.text "message"
    t.boolean "consent", default: false, null: false
    t.string "status", default: "fresh", null: false
    t.text "lost_reason"
    t.bigint "owner_id"
    t.date "follow_up_on"
    t.string "source", default: "website", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.bigint "company_id"
    t.datetime "converted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_leads_on_company_id"
    t.index ["follow_up_on"], name: "index_leads_on_follow_up_on"
    t.index ["occasion_id"], name: "index_leads_on_occasion_id"
    t.index ["owner_id"], name: "index_leads_on_owner_id"
    t.index ["status"], name: "index_leads_on_status"
    t.index ["work_email"], name: "index_leads_on_work_email"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.string "account", null: false
    t.bigint "amount_paise", null: false
    t.string "memo"
    t.datetime "posted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id", "account"], name: "index_ledger_entries_on_booking_id_and_account", unique: true
    t.index ["booking_id"], name: "index_ledger_entries_on_booking_id"
  end

  create_table "legal_pages", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title", null: false
    t.text "summary"
    t.text "body", null: false
    t.date "effective_on"
    t.boolean "published", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_legal_pages_on_slug", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kind"
    t.string "title", null: false
    t.text "body"
    t.string "url"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "occasions", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "tagline"
    t.text "description"
    t.string "emoji"
    t.string "theme", default: "saffron", null: false
    t.date "season_starts_on"
    t.date "season_ends_on"
    t.bigint "from_price_paise"
    t.jsonb "highlights", default: [], null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_occasions_on_slug", unique: true
  end

  create_table "package_items", force: :cascade do |t|
    t.bigint "package_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["package_id", "product_id"], name: "index_package_items_on_package_id_and_product_id", unique: true
    t.index ["package_id"], name: "index_package_items_on_package_id"
    t.index ["product_id"], name: "index_package_items_on_product_id"
  end

  create_table "packages", force: :cascade do |t|
    t.bigint "occasion_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.integer "min_qty", default: 25, null: false
    t.string "emoji"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["occasion_id"], name: "index_packages_on_occasion_id"
    t.index ["slug"], name: "index_packages_on_slug", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.string "method", null: false
    t.string "status", default: "pending", null: false
    t.bigint "amount_paise", null: false
    t.bigint "gateway_fee_paise", default: 0, null: false
    t.string "razorpay_order_id"
    t.string "razorpay_payment_id"
    t.string "reference"
    t.bigint "verified_by_id"
    t.datetime "verified_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_payments_on_booking_id"
    t.index ["razorpay_order_id"], name: "index_payments_on_razorpay_order_id", unique: true, where: "(razorpay_order_id IS NOT NULL)"
    t.index ["razorpay_payment_id"], name: "index_payments_on_razorpay_payment_id", unique: true, where: "(razorpay_payment_id IS NOT NULL)"
    t.index ["verified_by_id"], name: "index_payments_on_verified_by_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.string "sku", null: false
    t.string "name", null: false
    t.text "description"
    t.string "hsn_code", null: false
    t.decimal "gst_rate", precision: 5, scale: 2, default: "18.0", null: false
    t.integer "volume_units", default: 1, null: false
    t.jsonb "variants", default: {}, null: false
    t.boolean "brandable", default: false, null: false
    t.decimal "markup_override_pct", precision: 5, scale: 2
    t.string "emoji"
    t.string "review_status", default: "approved", null: false
    t.bigint "proposed_by_vendor_id"
    t.text "review_note"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["proposed_by_vendor_id"], name: "index_products_on_proposed_by_vendor_id"
    t.index ["review_status"], name: "index_products_on_review_status"
    t.index ["sku"], name: "index_products_on_sku", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.jsonb "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "site_events", force: :cascade do |t|
    t.string "kind", null: false
    t.string "path", null: false
    t.string "visitor_id", null: false
    t.string "label"
    t.string "target"
    t.string "referrer_host"
    t.string "device"
    t.datetime "created_at", null: false
    t.index ["created_at", "visitor_id"], name: "index_site_events_on_created_at_and_visitor_id"
    t.index ["kind", "created_at"], name: "index_site_events_on_kind_and_created_at"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.string "description"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_failure"
    t.text "metadata"
    t.integer "total_jobs", default: 0, null: false
    t.integer "completed_jobs", default: 0, null: false
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "batch_id"
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "ticket_comments", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.bigint "user_id"
    t.text "body", null: false
    t.boolean "internal", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id"], name: "index_ticket_comments_on_ticket_id"
    t.index ["user_id"], name: "index_ticket_comments_on_user_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "number"
    t.bigint "booking_id", null: false
    t.bigint "booking_recipient_id"
    t.bigint "company_id", null: false
    t.bigint "raised_by_id"
    t.bigint "assignee_id"
    t.string "category", default: "other", null: false
    t.string "priority", default: "normal", null: false
    t.string "status", default: "open", null: false
    t.string "subject", null: false
    t.text "description"
    t.text "resolution"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_tickets_on_assignee_id"
    t.index ["booking_id"], name: "index_tickets_on_booking_id"
    t.index ["booking_recipient_id"], name: "index_tickets_on_booking_recipient_id"
    t.index ["company_id"], name: "index_tickets_on_company_id"
    t.index ["number"], name: "index_tickets_on_number", unique: true
    t.index ["raised_by_id"], name: "index_tickets_on_raised_by_id"
    t.index ["status"], name: "index_tickets_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "role", null: false
    t.bigint "company_id"
    t.bigint "vendor_id"
    t.datetime "email_verified_at"
    t.datetime "last_sign_in_at"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["vendor_id"], name: "index_users_on_vendor_id"
  end

  create_table "vendor_offers", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.string "offerable_type", null: false
    t.bigint "offerable_id", null: false
    t.bigint "vendor_price_paise", null: false
    t.integer "moq", default: 1, null: false
    t.integer "capacity_per_week", default: 100, null: false
    t.integer "lead_time_days", default: 7, null: false
    t.integer "advance_pct", default: 0, null: false
    t.string "balance_terms", default: "on_delivery", null: false
    t.integer "credit_days", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["offerable_type", "offerable_id"], name: "index_vendor_offers_on_offerable"
    t.index ["vendor_id", "offerable_type", "offerable_id"], name: "index_vendor_offers_unique", unique: true
    t.index ["vendor_id"], name: "index_vendor_offers_on_vendor_id"
    t.check_constraint "advance_pct >= 0 AND advance_pct <= 100", name: "advance_pct_range"
    t.check_constraint "vendor_price_paise > 0", name: "vendor_price_positive"
  end

  create_table "vendor_payouts", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.bigint "assignment_id", null: false
    t.string "kind", null: false
    t.string "status", default: "due", null: false
    t.bigint "gross_paise", null: false
    t.bigint "penalty_paise", default: 0, null: false
    t.bigint "amount_paise", null: false
    t.date "due_on", null: false
    t.string "utr"
    t.text "penalty_reason"
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.datetime "paid_at"
    t.datetime "received_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_vendor_payouts_on_approved_by_id"
    t.index ["assignment_id", "kind"], name: "index_vendor_payouts_on_assignment_id_and_kind", unique: true
    t.index ["assignment_id"], name: "index_vendor_payouts_on_assignment_id"
    t.index ["status"], name: "index_vendor_payouts_on_status"
    t.index ["vendor_id"], name: "index_vendor_payouts_on_vendor_id"
  end

  create_table "vendor_regions", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.string "state", null: false
    t.string "city"
    t.string "pincode_prefix"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vendor_id"], name: "index_vendor_regions_on_vendor_id"
  end

  create_table "vendors", force: :cascade do |t|
    t.string "business_name", null: false
    t.string "legal_name"
    t.string "gstin"
    t.string "pan"
    t.string "phone"
    t.string "email"
    t.string "status", default: "pending", null: false
    t.text "rejection_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "fssai_number"
    t.string "contact_name"
    t.text "warehouse_address"
    t.string "warehouse_city"
    t.string "warehouse_state"
    t.string "warehouse_pincode"
    t.string "bank_account_name"
    t.text "bank_account_number"
    t.string "bank_ifsc"
    t.decimal "rating", precision: 3, scale: 2, default: "4.0", null: false
    t.datetime "approved_at"
    t.datetime "suspended_at"
    t.text "suspension_reason"
    t.index ["status"], name: "index_vendors_on_status"
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "webhook_events", force: :cascade do |t|
    t.string "provider", null: false
    t.string "event_id", null: false
    t.string "event_type"
    t.jsonb "payload", default: {}, null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "event_id"], name: "index_webhook_events_on_provider_and_event_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assignments", "bookings"
  add_foreign_key "assignments", "vendor_offers"
  add_foreign_key "assignments", "vendors"
  add_foreign_key "booking_recipients", "assignments"
  add_foreign_key "booking_recipients", "bookings"
  add_foreign_key "booking_recipients", "employees"
  add_foreign_key "bookings", "companies"
  add_foreign_key "bookings", "occasions"
  add_foreign_key "bookings", "users", column: "created_by_id"
  add_foreign_key "capacity_reservations", "assignments"
  add_foreign_key "capacity_reservations", "vendor_offers"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "employees", "companies"
  add_foreign_key "invoices", "bookings"
  add_foreign_key "invoices", "companies"
  add_foreign_key "invoices", "invoices", column: "original_invoice_id"
  add_foreign_key "lead_activities", "leads"
  add_foreign_key "lead_activities", "users"
  add_foreign_key "leads", "companies"
  add_foreign_key "leads", "occasions"
  add_foreign_key "leads", "users", column: "owner_id"
  add_foreign_key "ledger_entries", "bookings"
  add_foreign_key "notifications", "users"
  add_foreign_key "package_items", "packages"
  add_foreign_key "package_items", "products"
  add_foreign_key "packages", "occasions"
  add_foreign_key "payments", "bookings"
  add_foreign_key "payments", "users", column: "verified_by_id"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "vendors", column: "proposed_by_vendor_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "ticket_comments", "tickets"
  add_foreign_key "ticket_comments", "users"
  add_foreign_key "tickets", "booking_recipients"
  add_foreign_key "tickets", "bookings"
  add_foreign_key "tickets", "companies"
  add_foreign_key "tickets", "users", column: "assignee_id"
  add_foreign_key "tickets", "users", column: "raised_by_id"
  add_foreign_key "users", "companies"
  add_foreign_key "users", "vendors"
  add_foreign_key "vendor_offers", "vendors"
  add_foreign_key "vendor_payouts", "assignments"
  add_foreign_key "vendor_payouts", "users", column: "approved_by_id"
  add_foreign_key "vendor_payouts", "vendors"
  add_foreign_key "vendor_regions", "vendors"
end
