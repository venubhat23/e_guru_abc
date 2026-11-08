require "rails_helper"

RSpec.describe "Contact Us" do
  let(:valid) do
    { lead: { name: "Ravi Kumar", work_email: "ravi@acme.example", phone: "9876543210", company_name: "Acme",
              employee_count: "120", budget_per_employee_rupees: "1500", message: "Hi", consent: "1" } }
  end

  it "creates a lead and redirects to thank-you" do
    expect { post contact_path, params: valid }.to change(Lead, :count).by(1)
    expect(response).to redirect_to(thanks_contact_path)
    follow_redirect!
    expect(response.body).to include("Thank you, Ravi")
  end

  it "re-renders with errors" do
    post contact_path, params: { lead: valid[:lead].merge(work_email: "nope", consent: "0") }
    expect(response).to have_http_status(:unprocessable_content)
    expect(Lead.count).to eq(0)
  end

  it "silently drops honeypot submissions" do
    expect { post contact_path, params: { lead: valid[:lead].merge(website: "http://spam") } }.not_to change(Lead, :count)
    expect(response).to redirect_to(thanks_contact_path)
  end

  it "rate limits repeated submissions from one IP" do
    Rack::Attack.enabled = true
    statuses = Array.new(7) { |i| post(contact_path, params: { lead: valid[:lead].merge(work_email: "r#{i}@acme.example") }); response.status }
    expect(statuses.last).to eq(429)
    expect(Lead.count).to eq(5)
  ensure
    Rack::Attack.enabled = false
  end
end
