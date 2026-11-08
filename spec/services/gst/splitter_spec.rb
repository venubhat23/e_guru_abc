require "rails_helper"

RSpec.describe Gst::Splitter do
  it "splits intra-state supply into equal CGST and SGST" do
    r = described_class.call(taxable_paise: 10_000_00, rate: 18, place_of_supply: "Karnataka", supplier_state: "Karnataka")
    expect([ r.cgst_paise, r.sgst_paise, r.igst_paise ]).to eq([ 900_00, 900_00, 0 ])
    expect(r).to be_intra_state
  end

  it "charges IGST for inter-state supply" do
    r = described_class.call(taxable_paise: 10_000_00, rate: 12, place_of_supply: "Maharashtra", supplier_state: "Karnataka")
    expect([ r.cgst_paise, r.sgst_paise, r.igst_paise ]).to eq([ 0, 0, 1200_00 ])
    expect(r.total_paise).to eq(1200_00)
  end

  it "rounds each half to the nearest paisa" do
    r = described_class.call(taxable_paise: 333, rate: 5, place_of_supply: "Karnataka", supplier_state: "Karnataka")
    expect(r.cgst_paise).to eq(8)
  end

  it "uses the platform state from settings by default" do
    Setting[:platform_state] = "Delhi"
    expect(described_class.call(taxable_paise: 100_00, rate: 18, place_of_supply: "Delhi").igst_paise).to eq(0)
  end
end
