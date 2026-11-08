class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Avighna eGiftMitra <hello@egiftguru.in>")
  layout "mailer"
  helper ApplicationHelper
end
