require "rails_helper"

RSpec.describe Leads::Intake do
  let(:occasion) { create(:occasion) }
  let(:params) do
    { name: "Ravi Kumar", work_email: "ravi@acme.example", phone: "+91 98765 43210", company_name: "Acme",
      employee_count: 120, occasion_id: occasion.id, budget_per_employee_rupees: "1500", consent: "1" }
  end
  let!(:admin) { create(:user, :super_admin) }
  let!(:finance) { create(:user, :finance) }

  it "creates the lead, logs it, emails visitor + admins and notifies ops admins" do
    result = nil
    expect { result = described_class.call(params:) }
      .to change(Lead, :count).by(1)
      .and have_enqueued_mail(LeadMailer, :auto_reply)
      .and have_enqueued_mail(LeadMailer, :admin_alert)

    lead = result.lead
    expect(result).to be_success
    expect(lead.budget_per_employee_paise).to eq(1500_00)
    expect(lead.activities.pluck(:kind)).to eq([ "created" ])
    expect(admin.notifications.last.title).to eq("New lead: Acme")
    expect(finance.notifications).to be_empty
  end

  it "returns errors and sends nothing for invalid input" do
    result = described_class.call(params: params.merge(consent: "0"))
    expect(result).not_to be_success
    expect(result.lead.errors[:consent]).to be_present
    expect(enqueued_jobs).to be_empty
  end
end
