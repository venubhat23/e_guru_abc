class LeadMailer < ApplicationMailer
  def auto_reply(lead)
    @lead = lead
    mail to: lead.work_email, subject: "Thanks #{lead.name.split.first} — your gifting expert will call you shortly 🎁"
  end

  def admin_alert(lead)
    @lead = lead
    recipients = (Array(Setting[:lead_notification_emails]) + ENV.fetch("ADMIN_NOTIFICATION_EMAILS", "").split(",") +
                  User.active.where(role: %w[super_admin ops_admin]).pluck(:email_address)).map(&:strip).compact_blank.uniq
    return if recipients.empty?
    mail to: recipients, subject: "New lead: #{lead.company_name} (#{lead.employee_count || '?'} employees)"
  end
end
