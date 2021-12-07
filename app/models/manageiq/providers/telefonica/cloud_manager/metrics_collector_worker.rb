class ManageIQ::Providers::Telefonica::CloudManager::MetricsCollectorWorker < ::MiqEmsMetricsCollectorWorker
  require_nested :Runner

  self.default_queue_name = "telefonica"

  def friendly_name
    @friendly_name ||= "C&U Metrics Collector for Telefonica"
  end

  def self.ems_class
    ManageIQ::Providers::Telefonica::CloudManager
  end
end
