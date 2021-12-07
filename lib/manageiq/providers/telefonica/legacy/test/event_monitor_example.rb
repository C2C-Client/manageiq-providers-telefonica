###################################################################################
# Usage:
# bundle exec rails r gems/pending/telefonica/test/event_monitor_example.rb

require 'manageiq/providers/telefonica/legacy/telefonica_event_monitor'

def event_to_hash(event)
  hash = {}
  # copy content
  content = event.content
  hash[:content] = content.reject { |k, _v| k.start_with? "_context_" }

  # copy context
  hash[:context] = {}
  content.select { |k, _v| k.start_with? "_context_" }.each_pair do |k, v|
    hash[:context][k] = v
  end

  # copy attributes
  hash[:properties]     = event.properties
  hash[:user_id]        = event.user_id
  hash[:correlation_id] = event.correlation_id
  hash[:priority]       = event.priority
  hash[:content_type]   = event.content_type
  hash[:subject]        = event.subject
  hash[:reply_to]       = event.reply_to
  hash[:content_size]   = event.content_size
  hash
end

require 'pp'

TELEFONICA_RDU_DEV_SERVER = raise "please define"
TELEFONICA_RDU_DEV_PORT   = ""
TELEFONICA_RDU_USERNAME   = ""
TELEFONICA_RDU_PASSWORD   = ""

os_monitor = TelefonicaEventMonitor.new(:events_monitor => :amqp,
                                       :hostname       => TELEFONICA_RDU_DEV_SERVER,
                                       :username       => TELEFONICA_RDU_USERNAME,
                                       :password       => TELEFONICA_RDU_PASSWORD,
                                       :topics         => {"nova"    => "notifications.*",
                                                           "glance"  => "notifications.*",
                                                           "cinder"  => "notifications.*",
                                                           "heat"    => "notifications.*",
                                                           "quantum" => "notifications.*",
                                                           "neutron" => "notifications.*"})

Signal.trap("INT") { os_monitor.stop }

os_monitor.start
puts "Connected ... waiting for Telefonica events"
os_monitor.each do |event|
  puts "\n\nsaw event: #{event.inspect
       }"
  # pp event_to_hash event
end
