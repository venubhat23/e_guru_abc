require "rails_helper"

RSpec.describe Setting do
  it "returns defaults and stored overrides" do
    expect(described_class[:default_markup_pct]).to eq(40)
    described_class[:default_markup_pct] = 35
    expect(described_class[:default_markup_pct]).to eq(35)
  end

  it "rejects unknown keys" do
    expect { described_class[:nope] }.to raise_error(ArgumentError)
  end
end
