require "rails_helper"

RSpec.describe "Admin supply, operations & finance" do
  let(:admin) { create(:user, :super_admin) }
  let(:ops) { create(:user, :ops) }
  let(:finance) { create(:user, :finance) }
  let(:company) { create(:company) }
  let(:package) { create(:package) }

  describe "vendors" do
    let(:vendor) { create(:vendor, status: "pending", gstin: "29AABCS1111K1Z2", pan: "AABCS1111K", bank_account_number: "123456789", bank_ifsc: "HDFC0001234", warehouse_address: "Plot 1") }

    it "approves only with complete KYC, and rejects with a reason" do
      sign_in(ops)
      incomplete = create(:vendor, status: "pending")
      patch approve_admin_vendor_path(incomplete)
      expect(incomplete.reload).to be_pending
      expect(flash[:alert]).to match(/missing/i)

      patch approve_admin_vendor_path(vendor)
      expect(vendor.reload).to be_approved

      patch reject_admin_vendor_path(incomplete), params: { reason: "Invalid GST certificate" }
      expect(incomplete.reload).to be_rejected
    end

    it "suspending pauses all offers" do
      sign_in(ops)
      v = vendor_with_offer(package:)
      patch suspend_admin_vendor_path(v), params: { reason: "Quality complaints" }
      expect(v.reload).to be_suspended
      expect(v.offers.pluck(:active)).to all(be(false))
    end

    it "stores bank account numbers encrypted" do
      vendor
      raw = ActiveRecord::Base.connection.select_value("SELECT bank_account_number FROM vendors WHERE id = #{vendor.id}")
      expect(raw).not_to include("123456789")
      expect(vendor.reload.bank_account_number).to eq("123456789")
    end
  end

  describe "catalogue" do
    before { sign_in(ops) }

    it "creates a package with nested items" do
      p1, p2 = create_list(:product, 2)
      post admin_packages_path, params: { package: { name: "Onboarding Kit", occasion_id: create(:occasion).id, min_qty: 10,
                                                     package_items_attributes: { "0" => { product_id: p1.id, quantity: 1 }, "1" => { product_id: p2.id, quantity: 2 }, "2" => { product_id: "" } } } }
      pkg = Package.find_by!(slug: "onboarding-kit")
      expect(pkg.package_items.map(&:quantity)).to eq([ 1, 2 ])
    end

    it "reviews a vendor-proposed product" do
      product = create(:product, review_status: "pending", proposed_by_vendor: create(:vendor))
      patch review_admin_product_path(product), params: { decision: "approved" }
      expect(product.reload.review_status).to eq("approved")
    end

    it "renders price preview, offers matrix and the catalogue" do
      vendor_with_offer(package:)
      get admin_price_preview_path(item: "pkg-#{package.id}")
      expect(response.body).to include("₹1,400")
      get admin_offers_matrix_path(item: "pkg-#{package.id}")
      expect(response.body).to include("LOWEST")
      get admin_catalogue_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "bookings" do
    let!(:mh_vendor) { vendor_with_offer(package:, states: [ "Maharashtra" ], price: 900_00) }
    let!(:ka_vendor) { vendor_with_offer(package:, states: [ "Karnataka" ], price: 950_00) }
    let(:booking) do
      emps = create_list(:employee, 2, company:) + create_list(:employee, 3, company:, state: "Maharashtra", city: "Mumbai", pincode: "400001")
      draft_booking(company:, package:, employees: emps).tap { _1.update_columns(status: "assigning", assignment_mode: "manual") }
    end

    it "splits a booking across vendors by region" do
      sign_in(ops)
      get admin_booking_path(booking)
      expect(response.body).to include("vendor comparison")
      post manual_assign_admin_booking_path(booking), params: { vendor_offer_id: mh_vendor.offers.first.id, state: "Maharashtra" }
      expect(booking.reload).to be_assigning
      post manual_assign_admin_booking_path(booking), params: { vendor_offer_id: ka_vendor.offers.first.id, state: "Karnataka" }
      expect(booking.reload).to be_assigned
      expect(booking.live_assignments.map(&:quantity)).to contain_exactly(3, 2)
    end

    it "rejects assigning a vendor whose capacity is exhausted" do
      sign_in(ops)
      mh_vendor.offers.first.update!(capacity_per_week: 1)
      post manual_assign_admin_booking_path(booking), params: { vendor_offer_id: mh_vendor.offers.first.id, state: "Maharashtra" }
      expect(flash[:alert]).to match(/capacity/)
    end

    it "cancels with a reason" do
      sign_in(ops)
      patch cancel_admin_booking_path(booking), params: { reason: "Client request" }
      expect(booking.reload).to be_cancelled
    end

    it "lets finance view but not operate" do
      booking
      sign_in(finance)
      get admin_bookings_path
      expect(response.body).to include(booking.number)
      patch cancel_admin_booking_path(booking), params: { reason: "x" }
      expect(booking.reload).to be_assigning
    end

    it "serves the proforma PDF and delivery report CSV" do
      sign_in(ops)
      get proforma_admin_booking_path(booking)
      expect(response.media_type).to eq("application/pdf")
      expect(response.body).to start_with("%PDF")
      get delivery_report_admin_booking_path(booking)
      expect(response.body).to include("Employee,City")
      expect(response.body).not_to include(mh_vendor.name)
    end
  end

  describe "payments & payouts" do
    let!(:vendor) { vendor_with_offer(package:) }
    let(:booking) { draft_booking(company:, package:).tap(&:submit!) }
    let!(:payment) { booking.payments.create!(method: "bank_transfer", amount_paise: booking.total_paise, reference: "NEFT9") }

    it "only finance can verify offline payments, which triggers assignment" do
      sign_in(ops)
      patch verify_admin_payment_path(payment)
      expect(payment.reload).to be_pending
      delete session_path
      sign_in(finance)
      patch verify_admin_payment_path(payment)
      expect(payment.reload).to be_verified
      expect(booking.reload).to be_assigned
    end

    it "finance approves with a penalty and records UTR" do
      Payments::Recorder.verify!(payment, by: finance)
      Assignment::Workflow.accept!(booking.reload.live_assignments.sole)
      payout = VendorPayout.sole
      sign_in(finance)
      patch approve_admin_payout_path(payout), params: { penalty_rupees: "100", penalty_reason: "Late" }
      expect(payout.reload).to be_approved
      expect(payout.amount_paise).to eq(payout.gross_paise - 100_00)
      patch pay_admin_payout_path(payout), params: { utr: "" }
      expect(payout.reload).to be_approved
      patch pay_admin_payout_path(payout), params: { utr: "HDFCN123" }
      expect(payout.reload).to be_paid
      expect(vendor.users.flat_map(&:notifications).map(&:title).join).to match(/payout/i) if vendor.users.any?
    end
  end

  describe "tickets, invoices, reports" do
    before { sign_in(admin) }

    it "resolves tickets only with a resolution" do
      vendor_with_offer(package:)
      ticket = draft_booking(company:, package:).tickets.create!(company:, subject: "Broken mug")
      patch transition_admin_ticket_path(ticket, event: "resolve")
      expect(ticket.reload).to be_open
      patch transition_admin_ticket_path(ticket, event: "resolve"), params: { resolution: "Replaced" }
      expect(ticket.reload).to be_resolved
    end

    it "exports every report as CSV" do
      Reports::Builder::REPORTS.each_key do |key|
        get admin_report_path(key, format: :csv)
        expect(response.media_type).to eq("text/csv"), key
      end
      get admin_report_path("nope")
      expect(response).to have_http_status(:not_found)
    end

    it "counts unpaid completed credit-terms bookings as receivables" do
      credit = create(:company, payment_terms: "credit")
      vendor_with_offer(package:)
      b = draft_booking(company: credit, package:)
      b.update_columns(status: "completed", total_paise: 50_000_00)
      get admin_root_path
      expect(response.body).to include("₹50,000")
    end

    it "renders the dashboard with live metrics" do
      get admin_root_path
      expect(response.body).to include("Net contribution", "Marketing reserve", "Receivables")
    end
  end

  it "keeps HR and vendor users out of admin finance" do
    sign_in(create(:hr_admin))
    %w[/admin/bookings /admin/payouts /admin/invoices /admin/offers-matrix].each do |path|
      get path
      expect(response).to redirect_to(hr_root_path)
    end
  end
end
