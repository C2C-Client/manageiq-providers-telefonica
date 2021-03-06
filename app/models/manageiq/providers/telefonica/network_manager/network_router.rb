class ManageIQ::Providers::Telefonica::NetworkManager::NetworkRouter < ::NetworkRouter
  include ManageIQ::Providers::Telefonica::HelperMethods
  include ProviderObjectMixin
  include AsyncDeleteMixin

  supports :add_interface

  supports :create

  supports :delete do
    if ext_management_system.nil?
      unsupported_reason_add(:delete, _("The Network Router is not connected to an active %{table}") % {
        :table => ui_lookup(:table => "ext_management_systems")
      })
    end
    if network_ports.any?
      unsupported_reason_add(:delete, _("Unable to delete \"%{name}\" because it has associated ports.") % {
        :name => name
      })
    end
  end

  supports :update do
    if ext_management_system.nil?
      unsupported_reason_add(:update, _("The Network Router is not connected to an active %{table}") % {
        :table => ui_lookup(:table => "ext_management_systems")
      })
    end
  end

  supports :remove_interface

  def self.raw_create_network_router(ext_management_system, options)
    cloud_tenant = options.delete(:cloud_tenant)
    name = options.delete(:name)
    router = nil

    ext_management_system.with_provider_connection(connection_options(cloud_tenant)) do |service|
      router = service.create_router(name, options).body
    end
    {:ems_ref => router['id'], :name => options[:name]}
  rescue => e
    _log.error "router=[#{options[:name]}], error: #{e}"
    parsed_error = parse_error_message_from_neutron_response(e)
    error_message = case parsed_error
                    when /Quota exceeded for resources/
                      _("Quota exceeded for routers.")
                    else
                      parsed_error
                    end
    raise MiqException::MiqNetworkRouterCreateError, error_message, e.backtrace
  end

  def raw_delete_network_router
    with_notification(:network_router_delete,
                      :options => {
                        :subject => self,
                      }) do
      ext_management_system.with_provider_connection(connection_options(cloud_tenant)) do |service|
        service.delete_router(ems_ref)
      end
    end
  rescue => e
    _log.error "router=[#{name}], error: #{e}"
    raise MiqException::MiqNetworkRouterDeleteError, parse_error_message_from_neutron_response(e), e.backtrace
  end

  def delete_network_router_queue(userid)
    task_opts = {
      :action => "deleting Network Router for user #{userid}",
      :userid => userid
    }
    queue_opts = {
      :class_name  => self.class.name,
      :method_name => 'raw_delete_network_router',
      :instance_id => id,
      :priority    => MiqQueue::HIGH_PRIORITY,
      :role        => 'ems_operations',
      :zone        => ext_management_system.my_zone,
      :args        => []
    }
    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def raw_update_network_router(options)
    options.reject! { |k| k == :external_gateway_info }
    ext_management_system.with_provider_connection(connection_options(cloud_tenant)) do |service|
      service.update_router(ems_ref, options)
    end
  rescue => e
    _log.error "router=[#{name}], error: #{e}"
    raise MiqException::MiqNetworkRouterUpdateError, parse_error_message_from_neutron_response(e), e.backtrace
  end

  def update_network_router_queue(userid, options = {})
    task_opts = {
      :action => "updating Network Router for user #{userid}",
      :userid => userid
    }
    queue_opts = {
      :class_name  => self.class.name,
      :method_name => 'raw_update_network_router',
      :instance_id => id,
      :priority    => MiqQueue::HIGH_PRIORITY,
      :role        => 'ems_operations',
      :zone        => ext_management_system.my_zone,
      :args        => [options]
    }
    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def raw_add_interface(cloud_subnet_id)
    raise ArgumentError, _("Subnet ID cannot be nil") if cloud_subnet_id.nil?
    subnet = CloudSubnet.find(cloud_subnet_id)
    raise ArgumentError, _("Subnet cannot be found") if subnet.nil?

    ext_management_system.with_provider_connection(connection_options(cloud_tenant)) do |service|
      service.add_router_interface(ems_ref, subnet.ems_ref)
    end
  rescue => e
    _log.error "router=[#{name}], error: #{e}"
    raise MiqException::MiqNetworkRouterAddInterfaceError, parse_error_message_from_neutron_response(e), e.backtrace
  end

  def add_interface_queue(userid, cloud_subnet)
    task_opts = {
      :action => "Adding Interface to Network Router for user #{userid}",
      :userid => userid
    }
    queue_opts = {
      :class_name  => self.class.name,
      :method_name => 'raw_add_interface',
      :instance_id => id,
      :priority    => MiqQueue::HIGH_PRIORITY,
      :role        => 'ems_operations',
      :zone        => ext_management_system.my_zone,
      :args        => [cloud_subnet.id]
    }
    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def raw_remove_interface(cloud_subnet_id)
    raise ArgumentError, _("Subnet ID cannot be nil") if cloud_subnet_id.nil?
    subnet = CloudSubnet.find(cloud_subnet_id)
    raise ArgumentError, _("Subnet cannot be found") if subnet.nil?

    ext_management_system.with_provider_connection(connection_options(cloud_tenant)) do |service|
      service.remove_router_interface(ems_ref, subnet.ems_ref)
    end
  rescue => e
    _log.error "router=[#{name}], error: #{e}"
    raise MiqException::MiqNetworkRouterRemoveInterfaceError, parse_error_message_from_neutron_response(e), e.backtrace
  end

  def remove_interface_queue(userid, cloud_subnet)
    task_opts = {
      :action => "Removing Interface from Network Router for user #{userid}",
      :userid => userid
    }
    queue_opts = {
      :class_name  => self.class.name,
      :method_name => 'raw_remove_interface',
      :instance_id => id,
      :priority    => MiqQueue::HIGH_PRIORITY,
      :role        => 'ems_operations',
      :zone        => ext_management_system.my_zone,
      :args        => [cloud_subnet.id]
    }
    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def self.connection_options(cloud_tenant = nil)
    connection_options = {:service => "Network"}
    connection_options[:tenant_name] = cloud_tenant.name if cloud_tenant
    connection_options
  end

  def self.display_name(number = 1)
    n_('Network Router (Telefonica)', 'Network Routers (Telefonica)', number)
  end

  private

  def connection_options(cloud_tenant = nil)
    self.class.connection_options(cloud_tenant)
  end
end
