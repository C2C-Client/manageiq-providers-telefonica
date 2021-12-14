class ManageIQ::Providers::Telefonica::CloudManager::Provision < ::MiqProvisionCloud
  include ManageIQ::Providers::Telefonica::HelperMethods
  include_concern 'Cloning'
  include_concern 'Configuration'
  include_concern 'VolumeAttachment'
  include_concern 'OptionsHelper'
end
