class ManageIQ::Providers::Telefonica::CloudManager < ManageIQ::Providers::CloudManager
  #C2C Removed all swift manager dependency
  require_nested :AuthKeyPair
  require_nested :AvailabilityZone
  require_nested :AvailabilityZoneNull
  require_nested :CloudResourceQuota
  require_nested :CloudTenant
  require_nested :CloudVolume
  require_nested :CloudVolumeBackup
  require_nested :CloudVolumeSnapshot
  require_nested :CloudVolumeType
  require_nested :EventCatcher
  require_nested :EventParser
  require_nested :Flavor
  require_nested :HostAggregate
  require_nested :MetricsCapture
  require_nested :MetricsCollectorWorker
  require_nested :OrchestrationServiceOptionConverter
  require_nested :OrchestrationStack
  require_nested :OrchestrationTemplate
  require_nested :VnfdTemplate
  require_nested :Provision
  require_nested :ProvisionWorkflow
  require_nested :Refresher
  require_nested :RefreshParser
  require_nested :RefreshWorker
  require_nested :Template
  require_nested :Vm

  has_many :storage_managers,
           :foreign_key => :parent_ems_id,
           :class_name  => "ManageIQ::Providers::StorageManager",
           :autosave    => true

  include ManageIQ::Providers::Telefonica::CinderManagerMixin
  include ManageIQ::Providers::Telefonica::ManagerMixin
  include ManageIQ::Providers::Telefonica::IdentitySyncMixin

  supports :provisioning
  supports :cloud_tenant_mapping do
    if defined?(self.class.parent::CloudManager::CloudTenant) && !tenant_mapping_enabled?
      unsupported_reason_add(:cloud_tenant_mapping, _("Tenant mapping is disabled on the Provider"))
    elsif !defined?(self.class.parent::CloudManager::CloudTenant)
      unsupported_reason_add(:cloud_tenant_mapping, _("Tenant mapping is supported only when CloudTenant exists "\
                                                      "on the CloudManager"))
    end
  end
  supports :cinder_service
  supports :create_host_aggregate

  before_create :ensure_managers,
                :ensure_cinder_managers

  before_update :ensure_managers_zone_and_provider_region

  def hostname_required?
    enabled?
  end

  def ensure_managers_zone_and_provider_region
    if network_manager
      network_manager.zone_id         = zone_id
      network_manager.provider_region = provider_region
    end

    if cinder_manager
      cinder_manager.zone_id         = zone_id
      cinder_manager.provider_region = provider_region
    end
  end

  def ensure_network_manager
    build_network_manager(:type => 'ManageIQ::Providers::Telefonica::NetworkManager') unless network_manager
  end

  def ensure_cinder_manager
    return false if cinder_manager
    build_cinder_manager(:type => 'ManageIQ::Providers::Telefonica::StorageManager::CinderManager')
    true
  end

  def ensure_swift_manager
    true
  end

  after_save :save_on_other_managers

  def save_on_other_managers
    storage_managers.update_all(:tenant_mapping_enabled => tenant_mapping_enabled)
    if network_manager
      network_manager.tenant_mapping_enabled = tenant_mapping_enabled
      network_manager.save!
    end
  end

  def supports_cloud_tenants?
    true
  end

  def cinder_service
    vs = telefonica_handle.detect_volume_service
    vs&.name == :cinder ? vs : nil
  end

  def self.ems_type
    @ems_type ||= "telefonica".freeze
  end

  def self.description
    @description ||= "Telefonica".freeze
  end

  def self.default_blacklisted_event_names
    %w(
      identity.authenticate
      scheduler.run_instance.start
      scheduler.run_instance.scheduled
      scheduler.run_instance.end
    )
  end

  def self.api_allowed_attributes
    %w[keystone_v3_domain_id].freeze
  end

  def hostname_uniqueness_valid?
    return unless hostname_required?
    return unless hostname.present? # Presence is checked elsewhere

    existing_providers = Endpoint.where(:hostname => hostname.downcase)
                                 .where.not(:resource_id => id).includes(:resource)
                                 .select do |endpoint|
                                   unless endpoint.resource.nil?
                                     endpoint.resource.uid_ems == keystone_v3_domain_id &&
                                       endpoint.resource.provider_region == provider_region
                                   end
                                 end

    errors.add(:hostname, "has already been taken") if existing_providers.any?
  end

  def supports_port?
    true
  end

  def supports_api_version?
    true
  end

  def supports_security_protocol?
    true
  end

  def supported_auth_types
    %w(default amqp ssh_keypair)
  end

  def supported_catalog_types
    %w(telefonica)
  end

  def supports_provider_id?
    true
  end

  def supports_cinder_service?
    telefonica_handle.detect_volume_service.name == :cinder
  end

  def supports_authentication?(authtype)
    supported_auth_types.include?(authtype.to_s)
  end

  def required_credential_fields(type)
    case type.to_s
    when 'ssh_keypair' then [:userid, :auth_key]
    else                    [:userid, :password]
    end
  end

  def authentication_status_ok?(type = nil)
    return true if type == :ssh_keypair
    super
  end

  def authentications_to_validate
    authentication_for_providers.collect(&:authentication_type) - [:ssh_keypair]
  end

  #
  # Operations
  #

  def vm_start(vm, _options = {})
    vm.start
  rescue => err
    _log.error "vm=[#{vm.name}], error: #{err}"
  end

  def vm_stop(vm, _options = {})
    vm.stop
  rescue => err
    _log.error "vm=[#{vm.name}], error: #{err}"
  end

  def vm_pause(vm, _options = {})
    vm.pause
  rescue => err
    _log.error "vm=[#{vm.name}], error: #{err}"
  end

  def vm_suspend(vm, _options = {})
    vm.suspend
  rescue => err
    _log.error "vm=[#{vm.name}], error: #{err}"
  end

  def vm_shelve(vm, _options = {})
    vm.shelve
  rescue => err
    _log.error "vm=[#{vm.name}], error: #{err}"
  end

  def vm_shelve_offload(vm, _options = {})
    vm.shelve_offload
  rescue => err
    _log.error "vm=[#{vm.name}], error: #{err}"
  end

  def vm_destroy(vm, _options = {})
    vm.vm_destroy
  rescue => err
    _log.error "vm=[#{vm.name}], error: #{err}"
  end

  def vm_reboot_guest(vm, _options = {})
    vm.reboot_guest
  rescue => err
    _log.error "vm=[#{vm.name}], error: #{err}"
  end

  def vm_reset(vm, _options = {})
    vm.reset
  rescue => err
    _log.error "vm=[#{vm.name}], error: #{err}"
  end

  def vm_create_snapshot(vm, options = {})
    log_prefix = "vm=[#{vm.name}]"

    miq_telefonica_instance = MiqTelefonicaInstance.new(vm.ems_ref, telefonica_handle)
    snapshot = miq_telefonica_instance.create_snapshot(options)
    Notification.create(:type => :vm_snapshot_success, :subject => vm, :options => {:snapshot_op => 'create'})
    snapshot_id = snapshot["id"]

    # Add new snapshot to the snapshots table.
    vm.snapshots.create!(
      :name        => options[:name],
      :description => options[:desc],
      :uid         => snapshot_id,
      :uid_ems     => snapshot_id,
      :ems_ref     => snapshot_id,
      :create_time => snapshot["created"]
    )

    return snapshot_id
  rescue => err
    _log.error "#{log_prefix}, error: #{err}"
    _log.debug { err.backtrace.join("\n") }
    raise
  end

  def vm_remove_snapshot(vm, options = {})
    snapshot_uid = options[:snMor]

    log_prefix = "snapshot=[#{snapshot_uid}]"

    miq_telefonica_instance = MiqTelefonicaInstance.new(vm.ems_ref, telefonica_handle)
    miq_telefonica_instance.delete_evm_snapshot(snapshot_uid)
    Notification.create(:type => :vm_snapshot_success, :subject => vm, :options => {:snapshot_op => 'remove'})

    # Remove from the snapshots table.
    ar_snapshot = vm.snapshots.find_by(:ems_ref  => snapshot_uid)
    _log.debug "#{log_prefix}: ar_snapshot = #{ar_snapshot.class.name}"
    ar_snapshot.destroy if ar_snapshot

    # Remove from the vms table.
    ar_template = miq_templates.find_by(:ems_ref  => snapshot_uid)
    _log.debug "#{log_prefix}: ar_template = #{ar_template.class.name}"
    ar_template.destroy if ar_template
  rescue => err
    _log.error "#{log_prefix}, error: #{err}"
    _log.debug { err.backtrace.join("\n") }
    raise
  end

  def vm_remove_all_snapshots(vm, options = {})
    vm.snapshots.each { |snapshot| vm_remove_snapshot(vm, :snMor => snapshot.uid) }
  end

  def vm_create_evm_snapshot(vm, options = {})
    require "TelefonicaExtract/MiqTelefonicaVm/MiqTelefonicaInstance"

    log_prefix = "vm=[#{vm.name}]"

    miq_telefonica_instance = MiqTelefonicaInstance.new(vm.ems_ref, telefonica_handle)
    miq_snapshot = miq_telefonica_instance.create_evm_snapshot(options)

    # Add new snapshot image to the vms table. Type is TemplateTelefonica.
    miq_templates.create!(
      :type     => "ManageIQ::Providers::Telefonica::CloudManager::Template",
      :vendor   => "telefonica",
      :name     => miq_snapshot.name,
      :uid_ems  => miq_snapshot.id,
      :ems_ref  => miq_snapshot.id,
      :template => true,
      :location => "unknown"
    )

    # Add new snapshot to the snapshots table.
    vm.snapshots.create!(
      :name        => miq_snapshot.name,
      :description => options[:desc],
      :uid         => miq_snapshot.id,
      :uid_ems     => miq_snapshot.id,
      :ems_ref     => miq_snapshot.id
    )
    return miq_snapshot.id
  rescue => err
    _log.error "#{log_prefix}, error: #{err}"
    _log.debug { err.backtrace.join("\n") }
    raise
  end

  def vm_delete_evm_snapshot(vm, image_id)
    require "TelefonicaExtract/MiqTelefonicaVm/MiqTelefonicaInstance"

    log_prefix = "snapshot=[#{image_id}]"

    miq_telefonica_instance = MiqTelefonicaInstance.new(vm.ems_ref, telefonica_handle)
    miq_telefonica_instance.delete_evm_snapshot(image_id)

    # Remove from the snapshots table.
    ar_snapshot = vm.snapshots.find_by(:ems_ref  => image_id)
    _log.debug "#{log_prefix}: ar_snapshot = #{ar_snapshot.class.name}"
    ar_snapshot.destroy if ar_snapshot

    # Remove from the vms table.
    ar_template = miq_templates.find_by(:ems_ref  => image_id)
    _log.debug "#{log_prefix}: ar_template = #{ar_template.class.name}"
    ar_template.destroy if ar_template
  rescue => err
    _log.error "#{log_prefix}, error: #{err}"
    _log.debug { err.backtrace.join("\n") }
    raise
  end

  def vm_attach_volume(vm, options)
    volume = CloudVolume.find_by(:id => options[:volume_id])
    volume.raw_attach_volume(vm.ems_ref, options[:device])
  end

  def vm_detach_volume(vm, options)
    volume = CloudVolume.find_by(:id => options[:volume_id])
    volume.raw_detach_volume(vm.ems_ref)
  end

  def create_host_aggregate(options)
    ManageIQ::Providers::Telefonica::CloudManager::HostAggregate.create_aggregate(self, options)
  end

  def create_host_aggregate_queue(userid, options)
    ManageIQ::Providers::Telefonica::CloudManager::HostAggregate.create_aggregate_queue(userid, self, options)
  end

  def self.event_monitor_class
    ManageIQ::Providers::Telefonica::CloudManager::EventCatcher
  end

  #
  # Statistics
  #

  def block_storage_disk_usage
    cloud_volumes.where.not(:status => "error").sum(:size).to_f +
      cloud_volume_snapshots.where.not(:status => "error").sum(:size).to_f
  end

  def self.display_name(number = 1)
    n_('Cloud Provider (Telefonica)', 'Cloud Providers (Telefonica)', number)
  end
end
