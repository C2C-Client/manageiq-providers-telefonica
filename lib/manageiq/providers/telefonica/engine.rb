module ManageIQ
  module Providers
    module Telefonica
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::Telefonica

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('TeleFonica Provider')
        end
      end
    end
  end
end
