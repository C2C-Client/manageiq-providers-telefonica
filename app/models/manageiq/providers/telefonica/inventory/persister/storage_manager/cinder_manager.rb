class ManageIQ::Providers::Telefonica::Inventory::Persister::StorageManager::CinderManager < ManageIQ::Providers::Telefonica::Inventory::Persister
  include ManageIQ::Providers::Telefonica::Inventory::Persister::Definitions::CloudCollections
  include ManageIQ::Providers::Telefonica::Inventory::Persister::Definitions::NetworkCollections
  include ManageIQ::Providers::Telefonica::Inventory::Persister::Definitions::StorageCollections

  def initialize_inventory_collections
    initialize_storage_inventory_collections

    initialize_cloud_inventory_collections
  end

  def initialize_cloud_inventory_collections
    %i(vms
       availability_zones
       hardwares
       cloud_tenants
       disks).each do |name|

      add_collection(cloud, name, shared_cloud_properties) do |builder|
        builder.add_properties(:strategy => :local_db_cache_all) unless name == :disks
        builder.add_properties(:complete => false) if name == :disks
      end
    end
  end

  private

  def shared_cloud_properties
    { :parent => manager.parent_manager }
  end
end
