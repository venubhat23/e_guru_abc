require "rails_helper"

RSpec.describe "Admin leads CRM" do
  let(:ops) { create(:user, :ops, name: "Opal Ops") }
  let!(:lead) { create(:lead, company_name: "Kaveri Textiles") }
  let!(:other) { create(:lead, company_name: "Monsoon Foods", status: "contacted") }

  before { sign_in(ops) }

  it "lists, filters and searches" do
    get admin_leads_path(status: "contacted")
    expect(response.body).to include("Monsoon Foods")
    expect(response.body).not_to include("Kaveri Textiles")
    get admin_leads_path(q: "kaveri")
    expect(response.body).to include("Kaveri Textiles")
    expect(response.body).not_to include("Monsoon Foods")
  end

  it "moves a lead through statuses and requires a lost reason" do
    patch transition_admin_lead_path(lead, event: :mark_contacted)
    expect(lead.reload).to be_contacted
    patch transition_admin_lead_path(lead, event: :mark_lost)
    expect(lead.reload).to be_contacted
    patch transition_admin_lead_path(lead, event: :mark_lost, lost_reason: "No budget")
    expect(lead.reload).to be_lost
    expect(lead.activities.where(kind: "status_change").last.user).to eq(ops)
  end

  it "rejects unknown events" do
    patch transition_admin_lead_path(lead, event: :destroy)
    expect(flash[:alert]).to match(/isn't allowed/)
  end

  it "assigns owner, follow-up and notes with activity log" do
    patch admin_lead_path(lead), params: { lead: { owner_id: ops.id, follow_up_on: Date.tomorrow } }
    post admin_lead_notes_path(lead), params: { lead_activity: { body: "Called, wants samples" } }
    lead.reload
    expect(lead.owner).to eq(ops)
    expect(lead.activities.pluck(:kind)).to include("owner_change", "follow_up", "note")
  end

  it "converts a lead to a company" do
    post convert_admin_lead_path(lead), params: { company: { legal_name: "Kaveri Textiles Pvt Ltd", state: "Tamil Nadu" } }
    company = Company.last
    expect(response).to redirect_to(admin_company_path(company))
    expect(lead.reload.company).to eq(company)
    expect(lead).to be_won
  end
end
