class ManageIQ::Providers::Telefonica::NetworkManager::RefreshWorker < ::MiqEmsRefreshWorker
  require_nested :Runner

  def self.ems_class
    ManageIQ::Providers::Telefonica::NetworkManager
  end

  def self.settings_name
    :ems_refresh_worker_telefonica_network
  end
end
