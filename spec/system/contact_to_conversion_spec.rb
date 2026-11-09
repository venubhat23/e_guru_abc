require "rails_helper"

RSpec.describe "Visitor submits Contact Us and admin converts the lead" do
  let!(:occasion) { create(:occasion, name: "Diwali", slug: "diwali") }
  let!(:admin) { create(:user, :super_admin, name: "Aarav Mehta", email_address: "admin@egiftguru.test") }

  it "works end to end" do
    visit root_path
    click_link "Request quote", match: :first

    fill_in "Your name", with: "Kiran Rao"
    fill_in "Work email", with: "kiran@zenith.example"
    fill_in "Phone", with: "+91 98765 43210"
    fill_in "Company", with: "Zenith Pharma"
    fill_in "Number of employees", with: "200"
    select "Diwali", from: "Occasion"
    fill_in "Budget per employee (₹)", with: "1500"
    check "lead_consent"
    perform_enqueued_jobs { click_button "Send my enquiry" }

    expect(page).to have_content("Thank you, Kiran!")
    auto_reply = ActionMailer::Base.deliveries.find { _1.to == [ "kiran@zenith.example" ] }
    expect(auto_reply.subject).to include("Thanks Kiran")
    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include("admin@egiftguru.test")

    sign_in(admin)
    expect(page).to have_current_path(admin_root_path)
    click_link "Leads CRM"
    within("table") { click_link "Kiran Rao" }
    expect(page).to have_content("Zenith Pharma")
    expect(page).to have_content("₹3,00,000") # estimated deal size: 200 × ₹1,500

    click_button "Mark contacted"
    expect(page).to have_content("Lead moved to Contacted")

    fill_in "company_gstin", with: "29AAACZ1234A1Z5"
    select "Karnataka", from: "company_state"
    click_button "Convert to company"

    expect(page).to have_content("Zenith Pharma created from lead")
    expect(Lead.last).to be_won
    expect(Company.last.gstin).to eq("29AAACZ1234A1Z5")
  end
end
