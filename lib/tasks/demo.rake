# Demo helpers for manual end-to-end testing until the HR booking wizard and vendor portal screens exist.
# They call the same services the real screens will use (emails, notifications, payouts, ledger all fire).
# Usage: bin/rails "demo:vendor_accept[BK2600006]"   — run `bin/rails -T demo` for the list.
namespace :demo do
  task guard: :environment do
    abort "demo tasks are disabled in production" if Rails.env.production?
    ActiveJob::Base.queue_adapter = :inline # deliver emails now (see /letter_opener)
  end

  def booking!(number) = Booking.find_by!(number: number.to_s.strip.upcase)

  def report(b)
    b.reload
    puts "#{b.number}: #{b.status_label} · #{b.company.name} · #{b.quantity} kits · total #{Inr.format(b.total_paise)} · paid #{Inr.format(b.paid_paise)}"
    b.assignments.order(:id).each { |a| puts "  assignment ##{a.id} #{a.vendor.name}: #{a.status_label} (#{a.quantity} kits, #{Inr.format(a.vendor_total_paise)})" }
    b.payouts.order(:id).each { |p| puts "  payout ##{p.id} #{p.kind} #{Inr.format(p.amount_paise)}: #{p.status}" }
    b.invoices.each { |i| puts "  #{i.kind_label} #{i.number} #{Inr.format(i.total_paise)}" }
  end

  desc "Reset all bookings/payments/payouts to the seeded sample set (numbers restart at BK2600001)"
  task reset: :guard do
    ActionMailer::Base.perform_deliveries = false
    PaperTrail.request(enabled: false) do
      [ TicketComment, Ticket, LedgerEntry, Invoice, VendorPayout, CapacityReservation, BookingRecipient, Payment, Assignment, Booking, DocumentSequence, WebhookEvent ].each(&:delete_all)
    end
    %w[bookings assignments booking_recipients payments vendor_payouts invoices tickets].each { ActiveRecord::Base.connection.reset_pk_sequence!(_1) }
    Notification.where(kind: %w[booking assignment payout ticket]).delete_all
    load Rails.root.join("db/seeds/operations.rb").to_s
    puts "Reset done: " + Booking.order(:id).map { "#{_1.number}=#{_1.status}" }.join(", ")
  end

  desc "HR books a package for N employees and submits it: demo:book[acme|bharat,package-slug,count,days_ahead]"
  task :book, %i[company package count days] => :guard do |_, a|
    company = a[:company].to_s.start_with?("b") ? Company.find_by!(display_name: "Bharat Retail") : Company.find_by!(display_name: "Acme Technologies")
    hr = company.hr_admins.first
    pkg = Package.find_by!(slug: a[:package] || "diwali-delight")
    emps = company.employees.where.not(address: "Address to be confirmed").order(:id).limit((a[:count] || 25).to_i)
    b = Bookings::Creator.call(company:, user: hr, bookable: pkg, employees: emps, requested_delivery_on: Date.current + (a[:days] || 15).to_i,
                               personalisation: { "card_message" => "Dear {name}, thank you! — Team #{company.name}" })
    Bookings::Submitter.submit!(b)
    report(b)
  end

  desc "HR admin approves a booking above the company approval limit"
  task :hr_approve, %i[booking] => :guard do |_, a|
    b = booking!(a[:booking])
    Bookings::Submitter.approve!(b)
    report(b)
  end

  desc "Simulate a successful Razorpay payment arriving via the signed webhook"
  task :razorpay_pay, %i[booking] => :guard do |_, a|
    b = booking!(a[:booking])
    secret = ENV["RAZORPAY_WEBHOOK_SECRET"].presence || "demo_secret"
    order = "order_demo_#{b.id}_#{SecureRandom.hex(3)}"
    b.payments.create!(method: "razorpay", amount_paise: b.balance_due_paise, razorpay_order_id: order)
    body = { event: "payment.captured", payload: { payment: { entity: { id: "pay_#{SecureRandom.hex(6)}", order_id: order, fee: (b.balance_due_paise * 0.02).round } } } }.to_json
    sig = OpenSSL::HMAC.hexdigest("SHA256", secret, body)
    result = Payments::RazorpayWebhook.new(raw_body: body, signature: sig, event_id: "evt_#{SecureRandom.hex(6)}", secret:).process!
    puts "webhook: #{result}"
    report(b)
  end

  desc "HR uploads an offline bank-transfer proof (finance then verifies it in Admin → Payments)"
  task :offline_pay, %i[booking] => :guard do |_, a|
    b = booking!(a[:booking])
    pdf = Prawn::Document.new { text "NEFT payment advice for #{b.number}", size: 18 }.render
    p = Payments::Recorder.record_offline!(booking: b, method: "bank_transfer", amount_paise: b.balance_due_paise, reference: "NEFT/DEMO/#{rand(10**6)}",
                                           proof: { io: StringIO.new(pdf), filename: "neft-#{b.number}.pdf", content_type: "application/pdf" })
    puts "Offline payment ##{p.id} pending verification → open /admin/payments/#{p.id}"
  end

  desc "Vendor accepts every offered assignment on a booking"
  task :vendor_accept, %i[booking] => :guard do |_, a|
    b = booking!(a[:booking])
    b.assignments.where(status: "offered").find_each { Assignment::Workflow.accept!(_1) }
    report(b)
  end

  desc "Vendor rejects the offered assignment(s): demo:vendor_reject[BK…,reason]"
  task :vendor_reject, %i[booking reason] => :guard do |_, a|
    b = booking!(a[:booking])
    b.assignments.where(status: "offered").find_each { Assignment::Workflow.reject!(_1, reason: a[:reason] || "Out of stock") }
    report(b)
  end

  desc "Vendor starts production, QC-ready and dispatches with AWB numbers (all accepted assignments)"
  task :vendor_dispatch, %i[booking] => :guard do |_, a|
    b = booking!(a[:booking])
    b.assignments.where(status: %w[accepted in_production ready]).find_each do |as|
      Assignment::Workflow.start_production!(as) if as.accepted?
      Assignment::Workflow.mark_ready!(as.reload) if as.reload.in_production?
      Assignment::Workflow.dispatch!(as.reload, tracking: as.recipients.to_h { |r| [ r.id, { courier: %w[Delhivery Blue\ Dart DTDC].sample, awb: "AWB#{rand(10**9..10**10 - 1)}" } ] })
    end
    report(b)
  end

  desc "Vendor uploads proof of delivery for every dispatched recipient"
  task :vendor_deliver, %i[booking] => :guard do |_, a|
    b = booking!(a[:booking])
    b.assignments.where(status: "dispatched").find_each { Assignment::Workflow.deliver!(_1) }
    report(b)
  end

  desc "HR confirms delivery (all recipients delivered)"
  task :hr_confirm, %i[booking] => :guard do |_, a|
    b = booking!(a[:booking])
    b.mark_delivered!
    Bookings::Completer.call(b)
    report(b)
  end

  desc "Vendor marks every PAID payout on a booking as received (completes the booking when all are in)"
  task :vendor_receive, %i[booking] => :guard do |_, a|
    b = booking!(a[:booking])
    b.payouts.where(status: "paid").find_each { Payouts::Workflow.receive!(_1) }
    report(b)
  end

  desc "HR raises a ticket on a booking: demo:ticket[BK…,subject]"
  task :ticket, %i[booking subject] => :guard do |_, a|
    b = booking!(a[:booking])
    t = b.tickets.create!(company: b.company, raised_by: b.created_by, booking_recipient: b.recipients.first, category: "damaged", priority: "high",
                          subject: a[:subject] || "Item damaged for #{b.recipients.first&.name}")
    puts "Ticket #{t.number} → /admin/tickets/#{t.id}"
  end

  desc "Run the SLA expiry job and the auto-confirm job now"
  task jobs: :guard do
    AssignmentSlaJob.perform_now
    AutoConfirmDeliveriesJob.perform_now
    puts "SLA + auto-confirm jobs ran. Breached now: #{Assignment.sla_breached.count}"
  end

  desc "Show a booking's status, assignments, payouts and invoices"
  task :status, %i[booking] => :guard do |_, a|
    report(booking!(a[:booking]))
  end
end
