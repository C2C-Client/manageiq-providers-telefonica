module TelefonicaHandle
  class IntrospectionDelegate < DelegateClass(Fog::Introspection::TeleFonica)
    include TelefonicaHandle::HandledList
    include Vmdb::Logging

    SERVICE_NAME = "Introspection"

    attr_reader :name

    def initialize(dobj, os_handle, name)
      super(dobj)
      @os_handle = os_handle
      @name      = name
    end
  end
end
