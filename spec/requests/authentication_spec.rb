require "rails_helper"

RSpec.describe "Authentication" do
  it "sends each role to its own portal" do
    { create(:user, :super_admin) => "/admin", create(:hr_admin) => "/hr", create(:vendor_owner) => "/vendor" }.each do |user, path|
      sign_in(user)
      expect(response).to redirect_to(path)
      delete session_path
    end
  end

  it "rejects bad passwords, inactive and unverified users" do
    sign_in(create(:user), password: "wrong")
    expect(flash[:alert]).to match(/don't match/)

    sign_in(create(:user, active: false))
    expect(flash[:alert]).to match(/deactivated/)

    sign_in(create(:user, :unverified))
    expect(response).to redirect_to(new_email_verification_path)
  end

  it "verifies email via signed token and signs the user in" do
    user = create(:vendor_owner, email_verified_at: nil)
    get email_verification_token_path(user.generate_token_for(:email_verification))
    expect(user.reload).to be_email_verified
    expect(response).to redirect_to(vendor_root_path)
  end

  it "rejects tampered verification tokens" do
    get email_verification_token_path("bogus")
    expect(response).to redirect_to(new_email_verification_path)
  end

  it "resets a password with a valid token" do
    user = create(:user)
    expect { post passwords_path, params: { email_address: user.email_address } }.to have_enqueued_mail(PasswordsMailer, :reset)
    put password_path(user.password_reset_token), params: { password: "NewPass@456", password_confirmation: "NewPass@456" }
    expect(response).to redirect_to(new_session_path)
    expect(User.authenticate_by(email_address: user.email_address, password: "NewPass@456")).to eq(user)
  end

  it "requires login for portals" do
    %w[/admin /hr /vendor /admin/leads].each do |path|
      get path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
