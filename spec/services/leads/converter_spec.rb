require "rails_helper"

RSpec.describe Leads::Converter do
  let(:ops) { create(:user, :ops) }
  let(:lead) { create(:lead, company_name: "Zenith Pharma", status: "proposal_sent") }

  it "creates a company, marks the lead won and logs the conversion atomically" do
    company = described_class.call(lead:, actor: ops, attributes: { gstin: "29AAACA1234A1Z5", state: "Karnataka" })
    lead.reload
    expect(company.legal_name).to eq("Zenith Pharma")
    expect(lead).to be_won
    expect(lead.company).to eq(company)
    expect(lead.converted_at).to be_present
    expect(lead.activities.pluck(:kind)).to include("converted", "status_change")
  end

  it "rolls everything back when company data is invalid" do
    expect { described_class.call(lead:, actor: ops, attributes: { gstin: "BAD" }) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(lead.reload).to be_proposal_sent
    expect(Company.count).to eq(0)
  end

  it "refuses lost or already converted leads" do
    lead.update!(status: "lost", lost_reason: "No budget")
    expect { described_class.call(lead:, actor: ops) }.to raise_error(described_class::Error)
  end
end
