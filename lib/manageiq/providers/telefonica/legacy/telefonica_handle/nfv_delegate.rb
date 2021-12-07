module TelefonicaHandle
  class NFVDelegate < DelegateClass(Fog::NFV::OpenStack)
    include TelefonicaHandle::HandledList
    include Vmdb::Logging

    SERVICE_NAME = "NFV".freeze

    attr_reader :name

    def initialize(dobj, os_handle, name)
      super(dobj)
      @os_handle = os_handle
      @name      = name
    end
  end
end
