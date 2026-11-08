# Handles a Contact Us submission: create the lead, log it, notify admins, auto-reply the visitor.
module Leads
  class Intake
    Result = Struct.new(:lead, :success?, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(params:, request: nil)
      @params = params
      @request = request
    end

    def call
      lead = Lead.new(@params)
      lead.ip_address = @request&.remote_ip
      lead.user_agent = @request&.user_agent.to_s.first(255)

      saved = Lead.transaction do
        lead.save && lead.log!("created", "Lead submitted via #{lead.source} contact form")
      end
      return Result.new(lead:, success?: false) unless saved

      LeadMailer.auto_reply(lead).deliver_later
      LeadMailer.admin_alert(lead).deliver_later
      Notifier.notify(Notifier.platform_admins, kind: "lead", title: "New lead: #{lead.company_name}",
                      body: "#{lead.name} · #{lead.employee_count || '?'} employees",
                      url: Rails.application.routes.url_helpers.admin_lead_path(lead))
      Result.new(lead:, success?: true)
    end
  end
end
