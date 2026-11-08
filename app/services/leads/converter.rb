# Converts a lead into a Company, marks it won and logs the activity, atomically.
module Leads
  class Converter
    class Error < StandardError; end

    def self.call(...) = new(...).call

    def initialize(lead:, actor:, attributes: {})
      @lead, @actor, @attributes = lead, actor, attributes
    end

    def call
      raise Error, "Lead is already converted" if @lead.converted?
      raise Error, "Lost leads cannot be converted" if @lead.lost?

      Lead.transaction do
        company = Company.create!({ legal_name: @lead.company_name }.merge(@attributes.to_h.compact_blank.symbolize_keys))
        @lead.actor = @actor
        @lead.company = company
        @lead.converted_at = Time.current
        @lead.mark_won! unless @lead.won?
        @lead.save! if @lead.changed?
        @lead.log!("converted", "Converted to company #{company.legal_name}", company_id: company.id)
        company
      end
    end
  end
end
