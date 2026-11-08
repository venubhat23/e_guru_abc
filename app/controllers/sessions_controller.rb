class SessionsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Too many attempts. Try again in a few minutes." }

  def new
    redirect_to portal_home_path(current_user) if authenticated?
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))
    if user.nil?
      redirect_to new_session_path, alert: "That email and password don't match. Please try again."
    elsif !user.active?
      redirect_to new_session_path, alert: "Your account has been deactivated. Contact support."
    elsif !user.email_verified?
      session[:unverified_email] = user.email_address
      redirect_to new_email_verification_path, alert: "Please verify your email address first — we've sent you a link."
    else
      start_new_session_for user
      redirect_to after_authentication_url, notice: "Welcome back, #{user.first_name}!"
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: "You've been signed out."
  end
end
