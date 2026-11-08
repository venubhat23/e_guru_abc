require "rails_helper"

RSpec.describe "Vendor signup" do
  let(:params) { { vendor_signup: { business_name: "Jaipur Crafts", name: "Asha", email_address: "asha@jaipurcrafts.example", phone: "9876543210", password: "Password@123", city: "Jaipur", terms: "1" } } }

  it "creates a pending vendor with an unverified owner and sends verification" do
    expect { post vendor_signup_path, params: }.to change(Vendor, :count).by(1).and have_enqueued_mail(UserMailer, :email_verification)
    vendor = Vendor.last
    expect(vendor).to be_pending
    owner = vendor.users.first
    expect(owner).to be_vendor_owner
    expect(owner).not_to be_email_verified
    expect(response).to redirect_to(new_session_path)
  end

  it "requires terms and rejects duplicate emails without partial records" do
    post vendor_signup_path, params: { vendor_signup: params[:vendor_signup].merge(terms: "0") }
    expect(response).to have_http_status(:unprocessable_content)
    create(:user, email_address: "asha@jaipurcrafts.example")
    expect { post vendor_signup_path, params: }.not_to change(Vendor, :count)
    expect(response.body).to include("already been taken")
  end
end
