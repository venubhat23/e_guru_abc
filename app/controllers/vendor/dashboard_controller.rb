class Vendor::DashboardController < Vendor::BaseController
  def show
    authorize :dashboard, :show?
    @vendor = Current.vendor
    @steps = [
      { label: "Create your account", done: true },
      { label: "Verify your email", done: current_user.email_verified? },
      { label: "Business details, GSTIN & PAN", done: @vendor.gstin.present? },
      { label: "Bank account & warehouse", done: false },
      { label: "KYC documents", done: false },
      { label: "Approval by Avighna eGiftMitra", done: @vendor.approved? }
    ]
  end
end
