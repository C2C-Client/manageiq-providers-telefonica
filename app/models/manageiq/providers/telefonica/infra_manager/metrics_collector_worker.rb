class ManageIQ::Providers::Telefonica::InfraManager::MetricsCollectorWorker < ::MiqEmsMetricsCollectorWorker
  require_nested :Runner

  self.default_queue_name = "telefonica_infra"

  def friendly_name
    @friendly_name ||= "C&U Metrics Collector for TelefonicaInfra"
  end

  def self.ems_class
    ManageIQ::Providers::Telefonica::InfraManager
  end

  def self.settings_name
    :ems_metrics_collector_worker_telefonica_infra
  end
end
