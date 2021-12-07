require 'manageiq/providers/telefonica/legacy/telefonica_event_monitor'
require 'manageiq/providers/telefonica/legacy/events/telefonica_rabbit_event_monitor'

describe TelefonicaEventMonitor do
  before :each do
    @receivers = {"nova" => @nova_receiver, "glance" => @glance_receiver}
    @topics = {"nova" => "nova_topic", "glance" => "glance_topic"}
    @receiver_options = {:capacity => 1, :duration => 1}
    @options = @receiver_options.merge(:topics => @topics)
    @rabbit_host = {:hostname => "rabbit_host", :username => "rabbit_user", :password => "rabbit_pass",
                    :events_monitor => :amqp, :port => 5672}
    @bad_host = {:hostname => "bad_host", :username => "bad_user", :password => "bad_pass"}
  end

  it "selects null event monitor when nothing is available" do
    opts = @options.merge(@bad_host)
    allow(TelefonicaRabbitEventMonitor).to receive(:test_connection).with(opts).and_return(false)

    expect(TelefonicaEventMonitor.new(opts).class).to eq TelefonicaNullEventMonitor
  end

  it "caches multiple event monitors for different keys" do
    rabbit_options = @options.merge(@rabbit_host)
    allow(TelefonicaRabbitEventMonitor).to receive(:test_connection).with(rabbit_options).and_return(true)
    rabbit_instance = TelefonicaEventMonitor.new(rabbit_options)
    expect(rabbit_instance.class).to eq TelefonicaRabbitEventMonitor

    # additionally, we should be able to access the event_monitor instance
    # directly from the parent event_monitor
    instance = TelefonicaEventMonitor.new(rabbit_options)
    expect(instance).to eq rabbit_instance
  end

  it "orders the event monitor plugins correctly" do
    plugins = TelefonicaEventMonitor.subclasses

    expect(plugins.first).to eq TelefonicaRabbitEventMonitor
    expect(plugins.last).to eq TelefonicaNullEventMonitor
  end
end
