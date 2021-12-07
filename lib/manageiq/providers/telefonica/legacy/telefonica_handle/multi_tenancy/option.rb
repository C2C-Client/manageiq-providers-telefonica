require 'manageiq/providers/telefonica/legacy/telefonica_handle/multi_tenancy/base'

module TelefonicaHandle
  module MultiTenancy
    class Option < TelefonicaHandle::MultiTenancy::Base
      def list
        @service.pagination_handle(@collection_type, @options.merge(:all_tenants => 'True'), @method).list
      end
    end
  end
end
