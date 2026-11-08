class EmailVerificationsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to new_email_verification_url, alert: "Too many requests. Try again later." }

  def new
    @email = session[:unverified_email]
  end

  def create
    user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)
    UserMailer.email_verification(user).deliver_later if user && !user.email_verified?
    redirect_to new_session_path, notice: "If that account needs verifying, a fresh link is on its way."
  end

  def show
    user = User.find_by_token_for(:email_verification, params[:token])
    if user
      user.verify_email!
      session.delete(:unverified_email)
      start_new_session_for user
      redirect_to portal_home_path(user), notice: "Email verified — welcome to Avighna eGiftMitra!"
    else
      redirect_to new_email_verification_path, alert: "That verification link is invalid or has expired."
    end
  end
end
