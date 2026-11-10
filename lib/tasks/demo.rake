# Wipes all business data so the end-to-end flow can be tested from scratch.
#
# KEEPS: admin users (super/ops/finance), platform settings, and website content
#        (occasions, FAQs, legal pages).
# DELETES: companies, HR & vendor users, vendors, offers, catalogue (categories,
#          products, packages), employees, leads, bookings, payments, assignments,
#          payouts, invoices, tickets, notifications, sessions, audit history.
#
#   bin/rails demo:reset_keep_admins
#
# Refuses to run in production unless CONFIRM=yes is set.
namespace :demo do
  desc "Delete all data except admin users, settings and website content"
  task reset_keep_admins: :environment do
    if Rails.env.production? && ENV["CONFIRM"] != "yes"
      abort "Refusing to wipe production data. Re-run with CONFIRM=yes if you really mean it."
    end

    admin_roles = User::PLATFORM_ROLES
    conn = ActiveRecord::Base.connection

    # Children before parents so foreign keys are never violated.
    tables = %w[
      capacity_reservations vendor_payouts ticket_comments tickets booking_recipients
      invoices ledger_entries payments assignments bookings
      vendor_offers vendor_regions employees lead_activities leads
      notifications sessions package_items packages products categories
      document_sequences webhook_events site_events versions
    ]

    ActiveRecord::Base.transaction do
      tables.each { |t| conn.execute("DELETE FROM #{conn.quote_table_name(t)}") }
      User.where.not(role: admin_roles).delete_all
      User.update_all(company_id: nil, vendor_id: nil)
      conn.execute("DELETE FROM vendors")
      conn.execute("DELETE FROM companies")

      # Uploaded files (KYC docs, payment proofs, product photos…) of the deleted records.
      kept_types = %w[User Occasion LegalPage Faq Setting]
      conn.execute("DELETE FROM active_storage_variant_records WHERE blob_id IN (SELECT blob_id FROM active_storage_attachments WHERE record_type NOT IN (#{kept_types.map { conn.quote(_1) }.join(',')}))")
      conn.execute("DELETE FROM active_storage_attachments WHERE record_type NOT IN (#{kept_types.map { conn.quote(_1) }.join(',')})")
    end
    ActiveStorage::Blob.unattached.find_each(&:purge_later) rescue nil

    puts "✔ Cleared. Kept #{User.count} admin user(s): #{User.pluck(:email_address).join(', ')}"
    puts "  Also kept: #{Occasion.count} occasions, #{Faq.count} FAQs, #{LegalPage.count} legal pages, settings."
  end
end
