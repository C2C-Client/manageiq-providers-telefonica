class ManageIQ::Providers::Telefonica::StorageManager::CinderManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
  include ManageIQ::Providers::Telefonica::EventCatcherMixin

  def add_telefonica_queue(event)
    event_hash = ManageIQ::Providers::Telefonica::StorageManager::CinderManager::EventParser.event_to_hash(event, @cfg[:ems_id])
    EmsEvent.add_queue('add', @cfg[:ems_id], event_hash)
  end
end
