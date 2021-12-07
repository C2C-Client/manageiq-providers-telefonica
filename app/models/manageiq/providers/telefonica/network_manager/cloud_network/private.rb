class ManageIQ::Providers::Telefonica::NetworkManager::CloudNetwork::Private < ManageIQ::Providers::Telefonica::NetworkManager::CloudNetwork
  def self.display_name(number = 1)
    n_('Cloud Network (Telefonica)', 'Cloud Networks (Telefonica)', number)
  end
end
