class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    @url = email_verification_token_url(user.generate_token_for(:email_verification))
    mail to: user.email_address, subject: "Verify your email for Avighna eGiftMitra"
  end
end
