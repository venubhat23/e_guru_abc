require "rails_helper"

RSpec.describe User do
  it { is_expected.to validate_presence_of(:name) }

  it "requires a company for HR roles and a vendor for vendor roles" do
    expect(build(:user, role: "hr_admin", company: nil)).not_to be_valid
    expect(build(:user, role: "vendor_staff", vendor: nil)).not_to be_valid
    expect(build(:hr_admin)).to be_valid
    expect(build(:vendor_owner)).to be_valid
  end

  it "forbids platform users from belonging to a tenant" do
    user = build(:user, role: "super_admin", company: build(:company))
    expect(user).not_to be_valid
    expect(user.errors[:company]).to be_present
  end

  it "rejects unknown roles" do
    expect(build(:user, role: "hacker")).not_to be_valid
  end

  it "normalises email and maps each role to a portal" do
    expect(create(:user, email_address: "  Admin@Example.COM ").email_address).to eq("admin@example.com")
    expect(build(:user, :finance).portal).to eq(:admin)
    expect(build(:hr_member).portal).to eq(:hr)
    expect(build(:vendor_owner).portal).to eq(:vendor)
  end

  it "issues email verification tokens that resolve to the user" do
    user = create(:user, :unverified)
    token = user.generate_token_for(:email_verification)
    expect(User.find_by_token_for(:email_verification, token)).to eq(user)
  end
end
