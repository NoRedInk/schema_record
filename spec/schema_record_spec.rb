RSpec.describe SchemaRecord do
  it "has a version number" do
    expect(SchemaRecord::VERSION).not_to be nil
  end
end
