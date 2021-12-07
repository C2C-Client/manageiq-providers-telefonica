module ManageIQ::Providers::Telefonica::CinderManagerMixin
  extend ActiveSupport::Concern
  include ::CinderManagerMixin

  included do
    has_one  :cinder_manager,
             :foreign_key => :parent_ems_id,
             :class_name  => "ManageIQ::Providers::StorageManager::CinderManager",
             :autosave    => true

    delegate :cloud_volumes,
             :cloud_volume_snapshots,
             :cloud_volume_backups,
             :cloud_volume_types,
             :to        => :cinder_manager,
             :allow_nil => true
  end
end
