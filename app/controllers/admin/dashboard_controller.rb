class Admin::DashboardController < Admin::BaseController
  def show
    authorize :dashboard, :show?
    leads = policy_scope(Lead)
    committed = Booking.committed
    ledger = Ledger::Poster.totals
    # Everything billed or billable (incl. completed credit-terms bookings) minus money received.
    billable = Booking::OPEN - %w[pending_approval] + %w[completed]
    receivable = Booking.where(status: billable).sum(:total_paise) -
                 Payment.where(status: "verified").joins(:booking).where(bookings: { status: billable }).sum(:amount_paise)
    @stats = {
      gmv: committed.sum(:hr_subtotal_paise), gross_profit: ledger[:revenue], net_contribution: ledger[:net_contribution],
      marketing_reserve: ledger[:marketing_reserve], receivables: [ receivable, 0 ].max, payables: VendorPayout.outstanding.sum(:amount_paise),
      overdue_slas: Assignment.sla_breached.count, overdue_payouts: VendorPayout.overdue.count, open_tickets: Ticket.unresolved.count,
      leads_new_week: leads.where(created_at: 7.days.ago..).count, follow_ups_due: leads.follow_up_due.count,
      manual_queue: Booking.where(status: "assigning").count, pending_payments: Payment.where(status: "pending").where.not(method: "razorpay").count,
      vendors_pending: Vendor.pending.count
    }
    @bookings_by_status = Booking::STATUS_LABELS.filter_map { |k, label| (c = Booking.where(status: k).count).positive? ? [ label, c ] : nil }.to_h
    @gmv_by_month = committed.where(created_at: 6.months.ago.beginning_of_month..).group_by_month(:created_at, format: "%b %y", last: 6).sum(:hr_subtotal_paise).transform_values { _1 / 100 }
    @margin_by_month = LedgerEntry.where(account: "revenue", posted_at: 6.months.ago.beginning_of_month..).group_by_month(:posted_at, format: "%b %y", last: 6).sum(:amount_paise).transform_values { _1 / 100 }
    @leads_by_status = Lead::STATUS_LABELS.to_h { |k, label| [ label, leads.where(status: k).count ] }
    @attention = Booking.where(status: %w[assigning disputed]).or(Booking.where(id: Assignment.sla_breached.select(:booking_id))).includes(:company, :bookable).recent.limit(6)
    @recent_leads = leads.includes(:occasion).recent.limit(5)
  end
end
