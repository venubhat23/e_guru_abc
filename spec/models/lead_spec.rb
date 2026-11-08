require "rails_helper"

RSpec.describe Lead do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:company_name) }
  it { is_expected.to validate_presence_of(:phone) }

  it "requires consent on create and a valid phone" do
    expect(build(:lead, consent: false)).not_to be_valid
    expect(build(:lead, phone: "12")).not_to be_valid
  end

  it "stores budget in paise from rupees input" do
    lead = build(:lead, budget_per_employee_rupees: "1,250.50")
    expect(lead.budget_per_employee_paise).to eq(125_050)
  end

  describe "state machine" do
    let(:admin) { create(:user, :ops) }
    let(:lead) { create(:lead).tap { _1.actor = admin } }

    it "starts as New and moves through the pipeline, logging each step" do
      expect(lead.status_label).to eq("New")
      lead.mark_contacted!
      lead.schedule_demo!
      lead.send_proposal!
      lead.mark_won!
      expect(lead.reload).to be_won
      log = lead.activities.where(kind: "status_change").pluck(:body)
      expect(log).to include("Status changed from New to Contacted", "Status changed from Proposal sent to Won")
      expect(lead.activities.first.user).to eq(admin)
    end

    it "cannot be lost without a reason" do
      expect { lead.mark_lost! }.to raise_error(AASM::InvalidTransition)
      lead.lost_reason = "Went with a competitor"
      lead.mark_lost!
      expect(lead.reload).to be_lost
    end

    it "cannot move from won back into the pipeline" do
      lead.mark_won!
      expect(lead.may_mark_contacted?).to be(false)
    end

    it "records versions with PaperTrail" do
      expect { lead.mark_contacted! }.to change { lead.versions.count }.by(1)
    end
  end
end
