class ManageIQ::Providers::Telefonica::CloudManager::AvailabilityZone < ::AvailabilityZone
  def block_storage_disk_capacity
    cluster = ext_management_system.provider.infra_ems.ems_clusters.find { |c| c.block_storage? == true }
    cluster.nil? ? 0 : cluster.aggregate_disk_capacity
  end

  def block_storage_disk_usage
    cloud_volumes.where.not(:status => "error").sum(:size).to_f
  end
end
