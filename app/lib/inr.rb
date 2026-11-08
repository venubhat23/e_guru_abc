# Formats money stored as integer paise in Indian Rupees with Indian digit grouping (1,00,000).
module Inr
  module_function

  def format(paise, symbol: true, decimals: :auto)
    return "—" if paise.nil?
    negative = paise.negative?
    rupees, rem = paise.abs.divmod(100)
    show_decimals = decimals == :auto ? rem.nonzero? : decimals
    str = group(rupees)
    str += ".#{rem.to_s.rjust(2, '0')}" if show_decimals
    str = "₹#{str}" if symbol
    negative ? "-#{str}" : str
  end

  def group(int)
    s = int.to_s
    return s if s.length <= 3
    last3 = s[-3..]
    rest = s[0...-3].reverse.scan(/\d{1,2}/).join(",").reverse
    "#{rest},#{last3}"
  end

  def to_paise(rupees)
    return nil if rupees.blank?
    (BigDecimal(rupees.to_s.delete(",")) * 100).round.to_i
  end
end
