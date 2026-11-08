class PasswordsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[edit update]
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to new_password_url, alert: "Too many requests. Try again later." }

  def new; end

  def create
    if (user = User.active.find_by(email_address: params[:email_address].to_s.strip.downcase))
      PasswordsMailer.reset(user).deliver_later
    end
    redirect_to new_session_path, notice: "If that email is registered, password reset instructions are on their way."
  end

  def edit; end

  def update
    if params[:password].to_s.length < 8
      redirect_to edit_password_path(params[:token]), alert: "Password must be at least 8 characters."
    elsif @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      @user.update!(email_verified_at: Time.current) unless @user.email_verified?
      redirect_to new_session_path, notice: "Password updated. Please sign in."
    else
      redirect_to edit_password_path(params[:token]), alert: "Passwords did not match."
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: "That reset link is invalid or has expired."
  end
end
