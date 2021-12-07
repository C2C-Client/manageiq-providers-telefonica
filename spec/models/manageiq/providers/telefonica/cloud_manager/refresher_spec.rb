describe ManageIQ::Providers::Telefonica::CloudManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:telefonica)
  end
end
