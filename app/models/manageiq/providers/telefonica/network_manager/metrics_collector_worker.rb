class ManageIQ::Providers::Telefonica::NetworkManager::MetricsCollectorWorker < ::MiqEmsMetricsCollectorWorker
  require_nested :Runner

  self.default_queue_name = "telefonica_network"

  def friendly_name
    @friendly_name ||= "C&U Metrics Collector for Telefonica Network"
  end

  def self.ems_class
    ManageIQ::Providers::Telefonica::NetworkManager
  end

  def self.settings_name
    :ems_metrics_collector_worker_telefonica_network
  end
end
