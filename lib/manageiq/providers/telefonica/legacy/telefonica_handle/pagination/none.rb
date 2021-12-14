require 'manageiq/providers/telefonica/legacy/telefonica_handle/pagination/base'

module TelefonicaHandle
  module Pagination
    class None < TelefonicaHandle::Pagination::Base
      def list
        call_list_method(@collection_type, @options, @method)
      end
    end
  end
end
