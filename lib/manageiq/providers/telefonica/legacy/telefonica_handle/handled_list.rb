require 'manageiq/providers/telefonica/legacy/telefonica_handle/pagination/marker'
require 'manageiq/providers/telefonica/legacy/telefonica_handle/pagination/none'
require 'manageiq/providers/telefonica/legacy/telefonica_handle/pagination/page_number'

require 'manageiq/providers/telefonica/legacy/telefonica_handle/multi_tenancy/loop'
require 'manageiq/providers/telefonica/legacy/telefonica_handle/multi_tenancy/option'

module TelefonicaHandle
  module HandledList
    def handled_list(collection_type, options = {}, all_tenants = nil)
      # Will automatically handle multi-tenancy and pagination of all Fog list methods, so we always get all telefonica
      # entities back. The exceptions of each service and collection type will be solved in <service_name>)_delegate
      # classes by defining multi_tenancy_type and pagination_type methods base on collection_type
      # Example of call in refresh code
      # @compute_service.handled_list(:servers)
      # @orchestration_service.handled_list(:resources, :stack => stack)
      # By default, it calls :all method on the Fog collection, that has unified interface in all list methods in Fog
      # and always returns detailed list.
      multi_tenancy_class = if all_tenants
                              TelefonicaHandle::MultiTenancy::Option
                            else
                              default_multi_tenancy_class
                            end
      multi_tenancy_class.new(self, @os_handle, self.class::SERVICE_NAME, collection_type, options,
                              :all).list
    rescue Excon::Errors::Forbidden => err
      # It can happen user doesn't have rights to read some tenant, in that case log warning but continue refresh
      _log.warn "Forbidden to read the project: #{@os_handle.project_name}, for collection type: #{collection_type}, "\
                "in provider: #{@os_handle.address}. Message=#{err.message}"
      _log.warn err.backtrace.join("\n")
      []
    rescue Excon::Errors::Unauthorized => err
      # It can happen user doesn't have rights to read some tenant, in that case log warning but continue refresh
      _log.warn "Unauthorized to read the project: #{@os_handle.project_name}, for collection "\
                "type: #{collection_type}, in provider: #{@os_handle.address}. Message=#{err.message}"
      _log.warn err.backtrace.join("\n")
      []
    rescue Excon::Errors::NotFound, Fog::Errors::NotFound => err
      # It can happen that some data do not exist anymore, in that case log warning but continue refresh
      _log.warn "Data not found in project: #{@os_handle.project_name}, for collection type: #{collection_type}, "\
                "in provider: #{@os_handle.address}. Message=#{err.message}"
      _log.warn err.backtrace.join("\n")
      []
    rescue => err
      # Show any list related exception in a nice format.
      telefonica_service_name = Handle::SERVICE_NAME_MAP[self.class::SERVICE_NAME]

      _log.error "Unable to obtain collection: '#{collection_type}' in service: '#{telefonica_service_name}' "\
                 "using project scope: '#{@os_handle.project_name}' in provider: '#{@os_handle.address}'. "\
                 "Message=#{err.message}"
      _log.error err.backtrace.join("\n")

      raise MiqException::MiqTelefonicaApiRequestError,
            "Unable to obtain a collection: '#{collection_type}' in a service: '#{telefonica_service_name}' through "\
            " API. Please, fix your Telefonica installation and run refresh again."
    end

    def pagination_handle(collection_type, options = {}, method = :all)
      pagination_class.new(self, @os_handle, collection_type, options, method)
    end

    ###################################################################################################################
    # Override below methods to get special behaviour per service and collection. Unfortunately Telefonica does't handle
    # pagination and multitenancy the same for all services, nor for all API calls obtaining collections under one
    # service

    def default_pagination_limit
      1000
    end

    def more_pages?(_objects_on_page)
      # Different per Telefonica service, objects_on_page.response can contain metadata marking if there is a next page.
      # Already supported by some of the Fog::Collection
      true
    end

    def pagination_class
      # Using method, so we can e.g set pagination type per method name, e.g. when some collection doesn't support
      # pagination, like Heat resources, but others do
      # Allowed values TelefonicaHandle::Pagination::Marker, TelefonicaHandle::Pagination::PageNumber,
      # TelefonicaHandle::Pagination::None
      TelefonicaHandle::Pagination::Marker
    end

    def default_multi_tenancy_class
      # Using method, so we can e.g set multi_tenancy_type type per method name, e.g. when attribute all_tenants is
      # broken on some collections, so it's better to rather sent API request per tenant
      # Allowed values  TelefonicaHandle::MultiTenancy::Loop,  TelefonicaHandle::MultiTenancy::Option,
      # TelefonicaHandle::MultiTenancy::None
      TelefonicaHandle::MultiTenancy::Loop
    end
  end
end
