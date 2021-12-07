class ManageIQ::Providers::Telefonica::Inventory::Collector::NetworkManager < ManageIQ::Providers::Telefonica::Inventory::Collector
  include ManageIQ::Providers::Telefonica::Inventory::Collector::HelperMethods

  def floating_ips
    return @floating_ips if @floating_ips.any?
    @floating_ips = network_service.handled_list(:floating_ips, {}, telefonica_network_admin?)
  end

  def cloud_networks
    return @cloud_networks if @cloud_networks.any?
    @cloud_networks = safe_list { network_service.list_networks.body["networks"] }
  end

  def cloud_subnets
    return @cloud_subnets if @cloud_subnets.any?
    @cloud_subnets = network_service.handled_list(:subnets, {}, telefonica_network_admin?)
  end

  def network_ports
    return @network_ports if @network_ports.any?
    @network_ports = network_service.handled_list(:ports, {}, telefonica_network_admin?)
  end

  def network_routers
    return @network_routers if @network_routers.any?
    @network_routers = network_service.handled_list(:routers, {}, telefonica_network_admin?)
  end

  def security_groups
    return @security_groups if @security_groups.any?
    @security_groups = network_service.handled_list(:security_groups, {}, telefonica_network_admin?)
  end

  def security_groups_by_name
    @security_groups_by_name ||= Hash[security_groups.collect { |sg| [sg.name, sg.id] }]
  end

  def orchestration_stacks
    return [] unless orchestration_service

    return @orchestration_stacks unless @orchestration_stacks.nil?
    @orchestration_stacks = if telefonica_heat_global_admin?
                                orchestration_service.handled_list(:stacks, {:show_nested => true, :global_tenant => true}, true).collect(&:details)
                              else
                                orchestration_service.handled_list(:stacks, :show_nested => true).collect(&:details)
                              end
  rescue Excon::Errors::Forbidden
    # Orchestration service is detected but not open to the user
    $log.warn("Skip refreshing stacks because the user cannot access the orchestration service")
    []
  end

  def orchestration_resources(stack)
    @os_handle ||= manager.telefonica_handle
    safe_list { stack.resources }
  end
end
