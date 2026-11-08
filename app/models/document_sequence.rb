# Gapless, per-financial-year document numbers (INV/2026-27/0001) under a row lock.
class DocumentSequence < ApplicationRecord
  PREFIXES = { "tax_invoice" => "INV", "credit_note" => "CN", "ticket" => "TKT" }.freeze

  def self.financial_year(date = Date.current)
    start = date.month >= 4 ? date.year : date.year - 1
    "#{start}-#{(start + 1).to_s.last(2)}"
  end

  def self.next_number!(kind, date: Date.current)
    fy = financial_year(date)
    transaction(requires_new: true) do
      seq = lock.find_or_create_by!(kind:, financial_year: fy)
      seq.increment!(:last_number)
      [ "#{PREFIXES.fetch(kind)}/#{fy}/#{seq.last_number.to_s.rjust(4, '0')}", fy ]
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
