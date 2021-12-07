class ManageIQ::Providers::Telefonica::Inventory::Persister < ManageIQ::Providers::Inventory::Persister
  require_nested :CloudManager
  require_nested :NetworkManager
  require_nested :StorageManager
  require_nested :TargetCollection

  attr_reader :collector
  # Accessed by cloud parser.
  attr_reader :tag_mapper

  # @param manager [ManageIQ::Providers::BaseManager] A manager object
  # @param target [Object] A refresh Target object
  # @param collector [ManageIQ::Providers::Inventory::Collector] A Collector object
  def initialize(manager, target = nil, collector = nil)
    @manager   = manager
    @target    = target
    @collector = collector

    @collections = {}

    initialize_inventory_collections
  end

  protected

  def initialize_tag_mapper
    @tag_mapper = ContainerLabelTagMapping.mapper
    collections[:tags_to_resolve] = @tag_mapper.tags_to_resolve_collection
  end
end
