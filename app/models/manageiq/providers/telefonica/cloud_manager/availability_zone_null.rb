# An availability zone to represent the cases where Telefonica VMs may be
# launched into no availability zone
class ManageIQ::Providers::Telefonica::CloudManager::AvailabilityZoneNull < ManageIQ::Providers::Telefonica::CloudManager::AvailabilityZone
  default_value_for :name,   "No Availability Zone"
end
