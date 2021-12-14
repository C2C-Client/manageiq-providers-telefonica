require 'manageiq/providers/telefonica/legacy/telefonica_handle/pagination/base'

module TelefonicaHandle
  module Pagination
    class PageNumber < TelefonicaHandle::Pagination::Base
      def list
        # TBD, used e.g. by keystone v3
      end
    end
  end
end
