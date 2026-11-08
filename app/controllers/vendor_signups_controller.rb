# Public vendor landing page + application form. Creates a pending Vendor and its owner user.
class VendorSignupsController < PublicController
  def show
    @signup = VendorSignup.new
    @faqs = Faq.for("vendor")
  end

  def create
    @signup = VendorSignup.new(signup_params)
    if params.dig(:vendor_signup, :website).present? || @signup.save
      redirect_to new_session_path, notice: "Application received! Check #{@signup.email_address} to verify your email, then sign in to finish onboarding."
    else
      @faqs = Faq.for("vendor")
      render :show, status: :unprocessable_content
    end
  end

  private

  def signup_params
    params.require(:vendor_signup).permit(:business_name, :name, :email_address, :phone, :password, :city, :terms)
  end
end
