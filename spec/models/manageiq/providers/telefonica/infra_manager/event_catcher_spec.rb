describe ManageIQ::Providers::Telefonica::InfraManager::EventCatcher do
  before do
    @ems = FactoryBot.create(:ems_telefonica_infra)
    allow(@ems).to receive(:authentication_status_ok?).and_return(true)
    allow(ManageIQ::Providers::Telefonica::InfraManager::EventCatcher).to receive(:all_ems_in_zone).and_return([@ems])
  end

  it "logs info about EMS that do not have Event Monitors available" do
    allow(@ems).to receive(:event_monitor_available?).and_return(false)
    expect($log).to receive(:info).with(/Event Monitor unavailable for #{@ems.name}/)
    expect(ManageIQ::Providers::Telefonica::InfraManager::EventCatcher.all_valid_ems_in_zone).not_to include @ems
  end

  it "does not log info about unavailable Event Monitors when EMS can provide an event monitor" do
    allow(@ems).to receive(:event_monitor_available?).and_return(true)
    expect($log).not_to receive(:info).with(/Event Monitor unavailable for #{@ems.name}/)
    expect(ManageIQ::Providers::Telefonica::InfraManager::EventCatcher.all_valid_ems_in_zone).to include @ems
  end
end
