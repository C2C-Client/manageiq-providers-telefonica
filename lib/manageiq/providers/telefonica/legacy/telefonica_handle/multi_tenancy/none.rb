require 'manageiq/providers/telefonica/legacy/telefonica_handle/multi_tenancy/base'

module TelefonicaHandle
  module MultiTenancy
    class None < TelefonicaHandle::MultiTenancy::Base
      def list
        @service.pagination_handle(@collection_type, @options, @method)
      end
    end
  end
end
