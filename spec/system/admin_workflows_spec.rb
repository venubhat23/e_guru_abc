require "rails_helper"

# Real-browser (JS) click-through of every admin workflow.
RSpec.describe "Admin workflows", :js, type: :system do
  let(:admin) { create(:user, :super_admin, name: "Aarav Mehta") }
  let(:finance) { create(:user, :finance, name: "Rohan Iyer") }
  let(:company) { create(:company, legal_name: "Acme Tech", state: "Karnataka") }
  let(:package) { create(:package, name: "Diwali Delight") }

  def accept_confirm_and_click(*args, **opts)
    accept_confirm { click_on(*args, **opts) }
  end

  it "approves and rejects vendors from the approval queue" do
    complete = create(:vendor, business_name: "Ready Vendor", status: "pending", gstin: "29AABCS1111K1Z2", pan: "AABCS1111K",
                               bank_account_number: "1234567890", bank_ifsc: "HDFC0001234", warehouse_address: "Plot 9")
    create(:vendor, business_name: "Sketchy Vendor", status: "pending")
    sign_in(admin)
    click_on "Vendors"
    click_on "Ready Vendor"
    accept_confirm_and_click "Approve vendor"
    expect(page).to have_content("Ready Vendor approved")
    expect(complete.reload).to be_approved

    visit admin_vendors_path(status: "pending")
    click_on "Sketchy Vendor"
    click_on "Reject…"
    fill_in "reason", with: "GST certificate unreadable"
    click_on "Reject application"
    expect(page).to have_content("Application rejected")
    expect(page).to have_content("GST certificate unreadable")
  end

  it "builds a package with the add-item control" do
    create(:product, name: "Steel Bottle")
    create(:product, name: "Vegan Diary")
    create(:occasion, name: "Onboarding")
    sign_in(admin)
    visit new_admin_package_path
    fill_in "package_name", with: "Starter Kit"
    expect(page).to have_css("[data-nested-form-connected]") # Stimulus controllers load as async ES modules
    find("button", text: "Add item").click
    expect(page).to have_css("select[name*='[product_id]']", count: 4)
    all("[data-nested-row]").last.find("button[aria-label='Remove item']").click
    expect(page).to have_css("select[name*='[product_id]']", count: 3)
    selects = all("select[name*='[product_id]']")
    selects[0].select("Steel Bottle")
    selects[1].select("Vegan Diary")
    select "Onboarding", from: "package_occasion_id"
    click_on "Save package"
    expect(page).to have_content("Package created")
    expect(Package.find_by!(name: "Starter Kit").products.map(&:name)).to contain_exactly("Steel Bottle", "Vegan Diary")
  end

  it "manually assigns a booking split by state, then cancels another" do
    mh = vendor_with_offer(package:, states: [ "Maharashtra" ], price: 900_00)
    mh.update!(business_name: "Mumbai Gifts")
    ka = vendor_with_offer(package:, states: [ "Karnataka" ], price: 950_00)
    ka.update!(business_name: "Bengaluru Gifts")
    emps = create_list(:employee, 2, company:) + create_list(:employee, 2, company:, state: "Maharashtra", city: "Mumbai", pincode: "400001")
    booking = draft_booking(company:, package:, employees: emps).tap { _1.update_columns(status: "assigning", assignment_mode: "manual") }
    other = draft_booking(company:, package:, count: 2).tap { _1.update_columns(status: "assigning") }

    sign_in(admin)
    visit admin_booking_path(booking)
    within("tr", text: "Mumbai Gifts") do
      select "Maharashtra", from: "state"
      click_on "Assign"
    end
    expect(page).to have_content("2 kits offered to Mumbai Gifts")
    within("tr", text: "Bengaluru Gifts") { click_on "Assign" }
    expect(page).to have_content("2 kits offered to Bengaluru Gifts")
    expect(booking.reload).to be_assigned

    visit admin_booking_path(other)
    click_on "Cancel booking…"
    fill_in "reason", with: "Client postponed"
    click_on "Cancel booking"
    expect(page).to have_content("Booking cancelled")
    expect(other.reload).to be_cancelled
  end

  it "lets finance verify an offline payment and pay a vendor" do
    vendor = vendor_with_offer(package:, advance_pct: 50)
    vendor.update!(business_name: "SweetCraft")
    booking = draft_booking(company:, package:, count: 3).tap(&:submit!)
    payment = booking.payments.create!(method: "bank_transfer", amount_paise: booking.total_paise, reference: "NEFT/123")
    sign_in(finance)
    visit admin_payments_path(queue: "offline")
    click_on "Bank transfer / NEFT"
    accept_confirm_and_click "Verify"
    expect(page).to have_content("Payment verified")
    expect(payment.reload).to be_verified
    expect(booking.reload).to be_assigned

    Assignment::Workflow.accept!(booking.live_assignments.sole)
    visit admin_payouts_path
    click_on "SweetCraft"
    fill_in "penalty_rupees", with: "100"
    fill_in "penalty_reason", with: "Late"
    click_on "Approve"
    expect(page).to have_content("Payout approved")
    fill_in "utr", with: "HDFC000123"
    find("input[type=submit][value^='Mark paid']").click
    expect(page).to have_content("Marked as paid")
    expect(VendorPayout.sole).to be_paid
  end

  it "triages, comments on and resolves a ticket" do
    vendor_with_offer(package:)
    ticket = draft_booking(company:, package:).tickets.create!(company:, subject: "Mug arrived broken")
    sign_in(admin)
    click_on "Tickets"
    click_on "Mug arrived broken"
    fill_in "ticket_comment_body", with: "Replacement on its way"
    click_on "Add comment"
    expect(page).to have_content("Replacement on its way")
    select "Urgent", from: "ticket_priority"
    click_on "Save"
    expect(page).to have_content("Ticket updated")
    fill_in "resolution", with: "Replaced via Blue Dart"
    click_on "Mark resolved"
    expect(page).to have_content("Ticket resolved")
    expect(ticket.reload).to be_resolved
  end

  it "filters leads live, marks one lost via the dropdown and uses the notification bell" do
    create(:lead, company_name: "Kaveri Textiles", name: "Kiran Rao")
    create(:lead, company_name: "Monsoon Foods")
    Notifier.notify(admin, title: "New lead: Kaveri Textiles", url: "/admin/leads")
    sign_in(admin)
    find("button[aria-label='Notifications']").click
    expect(page).to have_content("New lead: Kaveri Textiles")
    click_on "Mark all read"
    expect(page).to have_content("All notifications marked as read")
    expect(admin.notifications.unread.count).to eq(0)

    visit admin_leads_path
    fill_in "q", with: "kaveri"
    expect(page).to have_no_content("Monsoon Foods")
    click_on "Kiran Rao"
    click_on "Mark lost…"
    fill_in "lost_reason", with: "Budget too low"
    click_on "Mark as lost"
    expect(page).to have_content("Lead moved to Lost")
  end

  it "opens reports, offers matrix and price preview" do
    vendor_with_offer(package:)
    sign_in(admin)
    click_on "Reports"
    click_on "GMV & margin by month"
    expect(page).to have_link("Export CSV")
    click_on "Offers matrix"
    expect(page).to have_content("LOWEST")
    visit admin_price_preview_path
    select "Diwali Delight", from: "item"
    click_on "Calculate"
    expect(page).to have_content("₹1,400")
  end

  context "on a phone" do
    before { page.current_window.resize_to(390, 844) }

    it "opens and closes the admin sidebar" do
      sign_in(admin)
      find("button[aria-label='Open menu']").click
      within("aside") { expect(page).to have_link("Bookings") }
      within("aside") { find("button[aria-label='Close menu']").click }
      expect(page).to have_css("[data-sidebar-target='panel'].-translate-x-full", visible: :all)
    end

    it "opens the public mobile menu" do
      visit root_path
      find("button[aria-label='Open menu']").click
      expect(page).to have_link("For vendors", visible: true)
    end
  end
end
