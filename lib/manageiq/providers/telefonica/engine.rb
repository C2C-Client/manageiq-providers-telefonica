module ManageIQ
  module Providers
    module Telefonica
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::Telefonica

        def self.plugin_name
          _('Telefonica Provider')
        end
      end
    end
  end
end
