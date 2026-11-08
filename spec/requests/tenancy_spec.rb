require "rails_helper"

RSpec.describe "Portal access & tenant isolation" do
  let(:company_a) { create(:company, legal_name: "Alpha Ltd") }
  let(:company_b) { create(:company, legal_name: "Beta Ltd") }
  let!(:hr_a) { create(:hr_admin, company: company_a, name: "Hema Alpha") }
  let!(:hr_b) { create(:hr_member, company: company_b, name: "Bala Beta") }
  let(:vendor_user) { create(:vendor_owner) }

  it "HR of company A only sees their own team" do
    sign_in(hr_a)
    get hr_team_members_path
    expect(response.body).to include("Hema Alpha")
    expect(response.body).not_to include("Bala Beta")
  end

  it "HR of company A cannot open a user from company B" do
    sign_in(hr_a)
    get hr_team_member_path(hr_b)
    expect(response).to have_http_status(:not_found)
  end

  it "HR company profile is always their own company" do
    sign_in(hr_a)
    get hr_company_path
    expect(response.body).to include("Alpha Ltd")
    expect(response.body).not_to include("Beta Ltd")
  end

  it "keeps each role out of other portals" do
    sign_in(hr_a)
    get admin_leads_path
    expect(response).to redirect_to(hr_root_path)
    get vendor_root_path
    expect(response).to redirect_to(hr_root_path)

    delete session_path
    sign_in(vendor_user)
    get hr_root_path
    expect(response).to redirect_to(vendor_root_path)
    get admin_root_path
    expect(response).to redirect_to(vendor_root_path)
  end

  it "blocks HR from a deactivated company" do
    company_a.update!(active: false)
    sign_in(hr_a)
    get hr_root_path
    expect(response).to redirect_to(new_session_path)
  end

  describe "platform roles" do
    let(:lead) { create(:lead) }

    it "lets finance view but not change leads" do
      sign_in(create(:user, :finance))
      get admin_lead_path(lead)
      expect(response).to have_http_status(:ok)
      patch transition_admin_lead_path(lead, event: :mark_contacted)
      expect(lead.reload).to be_fresh
      expect(flash[:alert]).to match(/access/)
    end

    it "only super admins change settings" do
      sign_in(create(:user, :ops))
      patch admin_settings_path, params: { settings: { default_markup_pct: "55" } }
      expect(Setting[:default_markup_pct]).to eq(40)
    end
  end

  it "notifications are private to their owner" do
    other = create(:user, :ops)
    note = Notification.create!(user: other, title: "Secret")
    sign_in(create(:user, :super_admin))
    get notification_path(note)
    expect(response).to have_http_status(:not_found)
    expect(note.reload.read_at).to be_nil
  end
end
