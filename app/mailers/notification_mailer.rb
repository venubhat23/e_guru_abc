class NotificationMailer < ApplicationMailer
  def event(user, title:, body: nil, url: nil)
    @user, @title, @body = user, title, body
    @url = url && URI.join(root_url, url).to_s
    mail to: user.email_address, subject: title
  end
end
