require "rails_helper"

RSpec.describe Inr do
  describe ".format" do
    it "uses Indian digit grouping" do
      expect(described_class.format(1_00_000_00)).to eq("₹1,00,000")
      expect(described_class.format(12_34_56_789_00)).to eq("₹12,34,56,789")
      expect(described_class.format(999_00)).to eq("₹999")
      expect(described_class.format(1_000_00)).to eq("₹1,000")
    end

    it "shows paise only when present" do
      expect(described_class.format(1_234_50)).to eq("₹1,234.50")
      expect(described_class.format(1_234_05)).to eq("₹1,234.05")
    end

    it "handles negatives, nil and no symbol" do
      expect(described_class.format(-5_00_000_00)).to eq("-₹5,00,000")
      expect(described_class.format(nil)).to eq("—")
      expect(described_class.format(10_00_000_00, symbol: false)).to eq("10,00,000")
    end
  end

  it "converts rupees to integer paise" do
    expect(described_class.to_paise("1,499.99")).to eq(149_999)
    expect(described_class.to_paise("")).to be_nil
  end
end
