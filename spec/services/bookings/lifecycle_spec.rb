require "rails_helper"

# Journey: HR books a Diwali package for 200 employees and pays; auto-assignment; vendor accepts,
# dispatches, delivers; finance pays advance and balance; vendor confirms; HR gets the invoice.
RSpec.describe "Booking lifecycle" do
  let(:company) { create(:company, state: "Karnataka", gstin: "29AAACA1234A1Z5") }
  let!(:hr) { create(:hr_admin, company:, email_address: "hr@acme.example") }
  let(:finance) { create(:user, :finance) }
  let(:package) { create(:package, name: "Diwali Delight", min_qty: 50) }
  let!(:vendor) { vendor_with_offer(package:, price: 1000_00, capacity_per_week: 500, advance_pct: 30) }
  let(:employees) { create_list(:employee, 200, company:) }

  it "runs end to end with correct money, payouts, ledger and invoice" do
    booking = Bookings::Creator.call(company:, user: hr, bookable: package, employees:, requested_delivery_on: 20.days.from_now.to_date,
                                     personalisation: { "card_message" => "Happy Diwali {name}!" })
    expect(booking.unit_price_paise).to eq(1400_00)
    expect(booking.hr_subtotal_paise).to eq(2_80_000_00)
    expect(booking.delivery_charge_paise).to eq(200 * 60_00)
    expect(booking.cgst_paise).to eq(booking.sgst_paise)
    expect(booking.recipients.first.card_message).to start_with("Happy Diwali Employee")

    booking.submit!
    expect(booking).to be_awaiting_payment
    payment = booking.payments.create!(method: "razorpay", amount_paise: booking.total_paise, razorpay_order_id: "order_d", gateway_fee_paise: 5000_00)
    Payments::Recorder.verify!(payment, by: finance)

    booking.reload
    expect(booking).to be_assigned
    assignment = booking.live_assignments.sole
    expect(assignment.vendor).to eq(vendor)
    expect(booking.vendor_subtotal_paise).to eq(2_00_000_00)

    Assignment::Workflow.accept!(assignment)
    expect(booking.reload).to be_confirmed
    expect(assignment.reload.accepted_at).to be_present # regression: AASM event `after` runs post-save
    expect(payment.reload.verified_at).to be_present
    advance = assignment.payouts.find_by!(kind: "advance")
    expect(advance.gross_paise).to eq(60_000_00)

    Assignment::Workflow.start_production!(assignment.reload)
    expect(booking.reload).to be_in_fulfilment
    Assignment::Workflow.mark_ready!(assignment.reload)
    Assignment::Workflow.dispatch!(assignment.reload, tracking: assignment.recipients.to_h { [ _1.id, { courier: "Delhivery", awb: "AWB#{_1.id}" } ] })
    expect(booking.reload).to be_dispatched
    Assignment::Workflow.deliver!(assignment.reload)
    balance = assignment.reload.payouts.find_by!(kind: "balance")
    expect(balance.gross_paise).to eq(1_40_000_00)
    expect(balance.due_on).to eq(Date.current)

    booking.reload.mark_delivered!
    [ advance, balance ].each do |po|
      Payouts::Workflow.approve!(po.reload, by: finance, penalty_paise: (po == balance ? 1000_00 : 0), penalty_reason: "Late by a day")
      Payouts::Workflow.pay!(po.reload, utr: "UTR#{po.id}")
    end
    expect(balance.reload.amount_paise).to eq(1_39_000_00)
    expect([ balance.approved_at, balance.paid_at, assignment.reload.dispatched_at, assignment.delivered_at ]).to all(be_present)
    expect(booking.reload).to be_delivered

    Payouts::Workflow.receive!(advance.reload)
    expect(booking.reload).to be_delivered
    expect { Payouts::Workflow.receive!(balance.reload) }.to have_enqueued_mail(BookingMailer, :completed)

    booking.reload
    expect(booking).to be_completed
    expect(booking.tax_invoice.number).to match(%r{\AINV/\d{4}-\d{2}/0001\z})
    ledger = booking.ledger_entries.to_h { [ _1.account, _1.amount_paise ] }
    expect(ledger).to eq("revenue" => 80_000_00, "marketing_reserve" => 40_000_00, "gateway_fees" => 5000_00)

    mail = BookingMailer.completed(booking)
    expect(mail.to).to include("hr@acme.example")
    expect(mail.attachments.map(&:filename)).to include(a_string_matching(/INV-.*\.pdf/), "delivery-report-#{booking.number}.csv")
    expect(mail.attachments.find { _1.filename.end_with?(".csv") }.decoded).not_to include(vendor.name)
  end

  it "cancels before confirmation with a full refund and credit note" do
    booking = draft_booking(company:, package:, count: 60).tap(&:submit!)
    Payments::Recorder.verify!(booking.payments.create!(method: "bank_transfer", amount_paise: booking.total_paise, reference: "NEFT1"), by: finance)
    expect(booking.reload).to be_assigned
    Bookings::Canceller.call(booking:, reason: "Event postponed")
    booking.reload
    expect(booking).to be_cancelled
    expect(booking.payments.sole).to be_refunded
    expect(booking.live_assignments).to be_empty
    expect(Assignment::CapacityChecker.remaining(vendor.offers.first, booking.requested_delivery_on)).to eq(500)
    cn = booking.invoices.sole
    expect(cn.kind).to eq("credit_note")
    expect(cn.number).to start_with("CN/")
    expect(cn.total_paise).to eq(booking.total_paise)
  end

  it "does not allow cancelling after vendor confirmation" do
    booking = draft_booking(company:, package:, count: 60).tap(&:submit!)
    Payments::Recorder.verify!(booking.payments.create!(method: "razorpay", amount_paise: booking.total_paise), by: finance)
    Assignment::Workflow.accept!(booking.reload.live_assignments.sole)
    expect { Bookings::Canceller.call(booking: booking.reload, reason: "Changed mind") }.to raise_error(Bookings::Canceller::Error)
  end

  it "blocks the balance payout while disputed" do
    booking = draft_booking(company:, package:, count: 50).tap(&:submit!)
    Payments::Recorder.verify!(booking.payments.create!(method: "razorpay", amount_paise: booking.total_paise), by: finance)
    a = booking.reload.live_assignments.sole
    Assignment::Workflow.accept!(a)
    Assignment::Workflow.start_production!(a.reload)
    Assignment::Workflow.mark_ready!(a.reload)
    Assignment::Workflow.dispatch!(a.reload, tracking: a.recipients.to_h { [ _1.id, { courier: "DTDC", awb: "X#{_1.id}" } ] })
    Assignment::Workflow.deliver!(a.reload)
    booking.reload.update!(dispute_reason: "Damaged")
    booking.dispute!
    balance = a.payouts.find_by!(kind: "balance")
    expect { Payouts::Workflow.approve!(balance, by: finance) }.to raise_error(Payouts::Workflow::Error)
  end

  it "expires assignments past their SLA and releases capacity (SLA job)" do
    other = vendor_with_offer(package:, price: 1100_00)
    booking = draft_booking(company:, package:, count: 50).tap(&:submit!)
    Payments::Recorder.verify!(booking.payments.create!(method: "razorpay", amount_paise: booking.total_paise), by: finance)
    first = booking.reload.live_assignments.sole
    first.update_column(:expires_at, 1.minute.ago)
    AssignmentSlaJob.perform_now
    expect(first.reload).to be_expired
    expect(booking.reload.live_assignments.sole.vendor).to eq(other)
    expect(vendor.performance[:rejection_pct]).to eq(100.0)
  end

  it "auto-confirms delivery after N days without open tickets" do
    booking = draft_booking(company:, package:, count: 50).tap(&:submit!)
    Payments::Recorder.verify!(booking.payments.create!(method: "razorpay", amount_paise: booking.total_paise), by: finance)
    a = booking.reload.live_assignments.sole
    Assignment::Workflow.accept!(a)
    Assignment::Workflow.start_production!(a.reload)
    Assignment::Workflow.mark_ready!(a.reload)
    Assignment::Workflow.dispatch!(a.reload, tracking: a.recipients.to_h { [ _1.id, { courier: "DTDC", awb: "X#{_1.id}" } ] })
    Assignment::Workflow.deliver!(a.reload)
    ticket = booking.tickets.create!(company:, subject: "Missing kit")
    travel_to(4.days.from_now) do
      AutoConfirmDeliveriesJob.perform_now
      expect(booking.reload).to be_dispatched
      ticket.update!(resolution: "Found")
      ticket.resolve!
      AutoConfirmDeliveriesJob.perform_now
      expect(booking.reload).to be_delivered
    end
  end

  it "routes credit-terms bookings straight to vendor assignment on submit" do
    credit = create(:company, state: "Karnataka", payment_terms: "credit")
    booking = draft_booking(company: credit, package:, count: 50)
    Bookings::Submitter.submit!(booking)
    expect(booking.reload).to be_assigned
    expect(booking.live_assignments.sole.vendor).to eq(vendor)
  end

  it "routes to assignment after HR approval for credit companies" do
    credit = create(:company, state: "Karnataka", payment_terms: "credit", approval_limit_paise: 1_00)
    booking = draft_booking(company: credit, package:, count: 50)
    Bookings::Submitter.submit!(booking)
    expect(booking).to be_pending_approval
    Bookings::Submitter.approve!(booking)
    expect(booking.reload).to be_assigned
  end

  it "numbers invoices per financial year" do
    travel_to(Date.new(2027, 3, 31)) { expect(DocumentSequence.next_number!("tax_invoice").first).to eq("INV/2026-27/0001") }
    travel_to(Date.new(2027, 4, 1)) { expect(DocumentSequence.next_number!("tax_invoice").first).to eq("INV/2027-28/0001") }
  end
end
