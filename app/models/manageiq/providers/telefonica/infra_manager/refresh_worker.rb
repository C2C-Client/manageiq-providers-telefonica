class ManageIQ::Providers::Telefonica::InfraManager::RefreshWorker < ::MiqEmsRefreshWorker
  require_nested :Runner

  def self.ems_class
    ManageIQ::Providers::Telefonica::InfraManager
  end

  # overriding queue_name_for_ems so PerEmsWorkerMixin picks up *all* of the
  # Telefonica-manager types from here.
  # This way, the refresher for Telefonica's InfraManager will refresh *all*
  # of the Telefonica inventory across all managers.
  class << self
    def queue_name_for_ems(ems)
      return ems unless ems.kind_of?(ExtManagementSystem)
      combined_managers(ems).collect(&:queue_name).sort
    end

    private

    def combined_managers(ems)
      [ems].concat(ems.child_managers)
    end
  end

  # MiQ complains if this isn't defined
  def queue_name_for_ems(ems)
  end

  def self.settings_name
    :ems_refresh_worker_telefonica_infra
  end
end
