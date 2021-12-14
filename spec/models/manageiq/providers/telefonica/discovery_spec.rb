describe ManageIQ::Providers::Telefonica::Discovery do
  it ".probe" do
    require 'ostruct'
    allow(ManageIQ::NetworkDiscovery::Port).to receive(:open?).and_return(true)

    allow(OpenSSL::SSL::SSLSocket).to receive(:new).and_raise(OpenSSL::SSL::SSLError)

    tcp_client = double(:syswrite => nil, :close => nil, :close_write => nil, :read => "TeleFonica Ironic API")
    allow(TCPSocket).to receive(:new).with('172.168.0.1', 6385).and_return(tcp_client)
    allow(TCPSocket).to receive(:new).with('172.168.0.1', 13_385).and_return(tcp_client)

    ost = OpenStruct.new(:ipaddr => '172.168.0.1', :hypervisor => [])
    described_class.probe(ost)
    expect(ost.hypervisor).to eq %i(telefonica_infra telefonica_infra)
  end
end
