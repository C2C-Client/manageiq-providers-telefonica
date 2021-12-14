describe ManageIQ::Providers::Telefonica::InfraManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:telefonica_infra)
  end
end
