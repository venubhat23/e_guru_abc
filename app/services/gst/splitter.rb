# Splits GST into CGST+SGST (intra-state) or IGST (inter-state) based on place of supply.
module Gst
  class Splitter
    Result = Struct.new(:cgst_paise, :sgst_paise, :igst_paise, keyword_init: true) do
      def total_paise = cgst_paise + sgst_paise + igst_paise
      def intra_state? = igst_paise.zero? && cgst_paise.positive?
    end

    def self.call(taxable_paise:, rate:, place_of_supply:, supplier_state: Setting[:platform_state])
      rate = BigDecimal(rate.to_s)
      if supplier_state.to_s.casecmp?(place_of_supply.to_s)
        half = (BigDecimal(taxable_paise.to_s) * rate / 200).round.to_i
        Result.new(cgst_paise: half, sgst_paise: half, igst_paise: 0)
      else
        Result.new(cgst_paise: 0, sgst_paise: 0, igst_paise: (BigDecimal(taxable_paise.to_s) * rate / 100).round.to_i)
      end
    end
  end
end
