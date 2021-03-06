# The OpentstackEventMonitor uses a plugin pattern to instantiate the correct
# subclass as a plugin based on the #available? class method implemented in each
# subclass
require 'more_core_extensions/core_ext/hash'
require 'more_core_extensions/core_ext/module'
require 'active_support/core_ext/class/subclasses'

class TelefonicaEventMonitor
  def self.new(options = {})
    # plugin initializer
    self == TelefonicaEventMonitor ? event_monitor(options) : super
  end

  def self.available?(options)
    event_monitor_class(options).available?(options)
  end

  DEFAULT_PLUGIN_PRIORITY = 0
  # Subclasses can override plugin priority to receive preferential treatment.
  # The higher the plugin_priority, the ealier the plugin will be tested for
  # availability.
  def self.plugin_priority
    DEFAULT_PLUGIN_PRIORITY
  end

  # Overridden for plugin support.  Allows this parent class to provide an
  # ordering of plugins.
  def self.subclasses
    # sort plugins on plugin_priorty
    super.sort_by(&:plugin_priority).reverse
  end

  def self.test_amqp_connection(options)
    event_monitor_selected_class(options).available?(options)
  end

  # See TelefonicaEventMonitor.new for details on event monitor selection
  def initialize(_options = {})
    # See TelefonicaEventMonitor.new
    raise NotImplementedError, "Cannot instantiate TelefonicaEventMonitor directly."
  end

  def start
    raise NotImplementedError, "must be implemented in subclass"
  end

  def stop
    raise NotImplementedError, "must be implemented in subclass"
  end

  def each_batch
    raise NotImplementedError, "must be implemented in subclass"
  end

  def each
    each_batch do |events|
      events.each { |e| yield e }
    end
  end

  cache_with_timeout(:event_monitor_class_cache) { Hash.new }
  cache_with_timeout(:event_monitor_cache) { Hash.new }

  def self.event_monitor_class(options)
    event_monitor_class = event_monitor_selected_class(options)

    key = event_monitor_key(options)
    event_monitor_class_cache[key] ||= available_event_monitor(event_monitor_class, options)
  end

  def self.event_monitor_selected_class(options)
    case options[:events_monitor]
    when :ceilometer
      TelefonicaCeilometerEventMonitor
    when :amqp
      TelefonicaRabbitEventMonitor
    else
      TelefonicaNullEventMonitor
    end
  end

  def self.available_event_monitor(event_monitor_class, options)
    monitor_available = begin
      event_monitor_class.available?(options)
    rescue => e
      $log.warn("MIQ(#{self}.#{__method__}) Error occured testing #{event_monitor_selected_class(options)}
                 for #{options[:hostname]}. Event collection will be disabled for
                 #{options[:hostname]}. #{e.message}")
      false
    end

    event_monitor_class = TelefonicaNullEventMonitor unless monitor_available
    event_monitor_class
  end

  # Select the best-fit plugin, or TelefonicaNullEventMonitor if no plugin will
  # work Return the plugin instance
  # Caches plugin instances by telefonica provider
  def self.event_monitor(options)
    key = event_monitor_key(options)
    event_monitor_cache[key] ||= event_monitor_class(options).new(options)
  end

  # this private marker is really here for looks
  # private_class_methods are marked below

  private

  def self.event_monitor_key(options)
    options.values_at(:events_monitor, :hostname, :port, :username, :password)
  end
  private_class_method :event_monitor_key

  def telefonica_event(_delivery_info, metadata, payload)
    TelefonicaEvent.new(payload,
                       :user_id      => payload["user_id"],
                       :priority     => metadata["priority"],
                       :content_type => metadata["content_type"],
                      )
  end
end

# Dynamically load all event monitor plugins
Dir.glob(File.join(File.dirname(__FILE__), "events/*event_monitor.rb")).each { |f| require f }
