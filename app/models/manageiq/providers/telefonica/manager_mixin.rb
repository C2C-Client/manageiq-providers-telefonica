module ManageIQ::Providers::Telefonica::ManagerMixin
  extend ActiveSupport::Concern
  include ManageIQ::Providers::Telefonica::HelperMethods

  included do
    after_save :stop_event_monitor_queue_on_change
    before_destroy :stop_event_monitor
  end

  alias_attribute :keystone_v3_domain_id, :uid_ems
  #
  # Telefonica interactions
  #
  module ClassMethods
    def amqp_available?(password, params)
      require 'manageiq/providers/telefonica/legacy/events/telefonica_rabbit_event_monitor'
      TelefonicaRabbitEventMonitor.available?(
        :hostname => params[:amqp_hostname],
        :username => params[:amqp_userid],
        :password => ManageIQ::Password.try_decrypt(password),
        :port     => params[:amqp_api_port]
      )
    end
    private :amqp_available?

    def ems_connect?(password, params, service)
      ems = new
      ems.name                   = params[:name].strip
      ems.provider_region        = params[:provider_region]
      ems.api_version            = params[:api_version].strip
      ems.security_protocol      = params[:default_security_protocol].strip
      ems.keystone_v3_domain_id  = params[:keystone_v3_domain_id]
      ems.project_name           = params[:project_name]


      user, hostname, port = params[:default_userid], params[:default_hostname].strip, params[:default_api_port].try(:strip)

      endpoint = {:role => :default, :hostname => hostname, :port => port, :security_protocol => ems.security_protocol}
      authentication = {:userid => user, :password => ManageIQ::Password.try_decrypt(password), :save => false, :role => 'default', :authtype => 'default'}
      ems.connection_configurations = [{:endpoint       => endpoint,
                                        :authentication => authentication}]

      begin
        ems.connect(:service => service)
      rescue => err
        miq_exception = translate_exception(err)
        raise unless miq_exception

        _log.error("Error Class=#{err.class.name}, Message=#{err.message}")
        raise miq_exception
      end
    end
    private :ems_connect?

    def raw_connect(password, params, service = "Compute")
      if params[:event_stream_selection] == 'amqp'
        amqp_available?(password, params)
      else
        ems_connect?(password, params, service)
      end
    end

    def translate_exception(err)
      require 'excon'
      case err
     when Excon::Errors::NotFound
        MiqException::MiqHostError.new("Endpoint not found.")
      when Excon::Errors::Unauthorized
        MiqException::MiqInvalidCredentialsError.new("Login failed due to a bad username or password.")
      when Excon::Errors::Timeout
        MiqException::MiqUnreachableError.new("Login attempt timed out")
      when Excon::Errors::SocketError
        MiqException::MiqHostError.new("Socket error: #{err.message}")
      when MiqException::MiqInvalidCredentialsError, MiqException::MiqHostError, MiqException::ServiceNotAvailable
        err
      else
        MiqException::MiqEVMLoginError.new("Unexpected response returned from system: #{parse_error_message_from_fog_response(err)}")
      end
    end
  end

  def auth_url
    self.class.auth_url(address, port)
  end

  def browser_url
    "http://#{address}/dashboard"
  end

  def telefonica_handle(options = {})
    require 'manageiq/providers/telefonica/legacy/telefonica_handle'
    @telefonica_handle ||= begin
      raise MiqException::MiqInvalidCredentialsError, "No credentials defined" if self.missing_credentials?(options[:auth_type])

      username = options[:user] || authentication_userid(options[:auth_type])
      password = options[:pass] || authentication_password(options[:auth_type])

      extra_options = {
        :ssl_ca_file    => ::Settings.ssl.ssl_ca_file,
        :ssl_ca_path    => ::Settings.ssl.ssl_ca_path,
        :ssl_cert_store => OpenSSL::X509::Store.new
      }
      extra_options[:domain_id]         = keystone_v3_domain_id
      extra_options[:region]            = provider_region if provider_region.present?
      extra_options[:omit_default_port] = ::Settings.ems.ems_telefonica.excon.omit_default_port
      extra_options[:read_timeout]      = ::Settings.ems.ems_telefonica.excon.read_timeout
      extra_options[:project_name]      =  project_name if project_name.present?


      osh = TelefonicaHandle::Handle.new(username, password, address, port, api_version, security_protocol, extra_options)
      osh.connection_options = {:instrumentor => $fog_log}
      osh
    end
  end

  def reset_telefonica_handle
    @telefonica_handle = nil
  end

  def connect(options = {})
    telefonica_handle(options).connect(options)
  end

  def connect_volume
    connect(:service => "Volume")
  end

  def connect_identity
    connect(:service => "Identity")
  end

  def event_monitor_options
    @event_monitor_options ||= begin
      opts = {:ems => self, :automatic_recovery => false, :recover_from_connection_close => false}

      ceilometer = connection_configuration_by_role("ceilometer")

      if ceilometer.try(:endpoint) && !ceilometer.try(:endpoint).try(:marked_for_destruction?)
        opts[:events_monitor] = :ceilometer
      elsif (amqp = connection_configuration_by_role("amqp"))
        opts[:events_monitor] = :amqp
        if (endpoint = amqp.try(:endpoint))
          opts[:hostname]          = endpoint.hostname
          opts[:port]              = endpoint.port
          opts[:security_protocol] = endpoint.security_protocol
        end

        if (authentication = amqp.try(:authentication))
          opts[:username] = authentication.userid
          opts[:password] = authentication.password
        end

        if (amqp_fallback1_endpoint = connection_configuration_by_role("amqp_fallback1").try(:endpoint))
          opts[:amqp_fallback_hostname1] = amqp_fallback1_endpoint.hostname
        end

        if (amqp_fallback2_endpoint = connection_configuration_by_role("amqp_fallback2").try(:endpoint))
          opts[:amqp_fallback_hostname2] = amqp_fallback2_endpoint.hostname
        end
      end
      opts
    end
  end

  def event_monitor_available?
    require 'manageiq/providers/telefonica/legacy/telefonica_event_monitor'
    TelefonicaEventMonitor.available?(event_monitor_options)
  rescue => e
    _log.error("Exception trying to find telefonica event monitor for #{name}(#{hostname}). #{e.message}")
    _log.error(e.backtrace.join("\n"))
    false
  end

  def sync_event_monitor_available?
    event_monitor_options[:events_monitor] == :ceilometer ? authentication_status_ok? : event_monitor_available?
  end

  def stop_event_monitor_queue_on_change
    if event_monitor_class && !self.new_record? && (authentications.detect{ |x| x.previous_changes.present? } ||
                                                    endpoints.detect{ |x| x.previous_changes.present? })
      _log.info("EMS: [#{name}], Credentials or endpoints have changed, stopping Event Monitor. It will be restarted by the WorkerMonitor.")
      stop_event_monitor_queue
      network_manager.stop_event_monitor_queue if try(:network_manager) && !network_manager.new_record?
      cinder_manager.stop_event_monitor_queue if try(:cinder_manager) && !cinder_manager.new_record?
    end
  end

  def stop_event_monitor_queue_on_credential_change
    # TODO(lsmola) this check should not be needed. Right now we are saving each individual authentication and
    # it is breaking the check for changes. We should have it all saved by autosave when saving EMS, so the code
    # for authentications needs to be rewritten.
    stop_event_monitor_queue_on_change
  end

  def translate_exception(err)
    self.class.translate_exception(err)
  end

  def verify_api_credentials(options = {})
    options[:service] = "Compute"
    with_provider_connection(options) {}
    true
  rescue => err
    miq_exception = translate_exception(err)
    raise unless miq_exception

    _log.error("Error Class=#{err.class.name}, Message=#{err.message}")
    raise miq_exception
  end
  private :verify_api_credentials

  def verify_amqp_credentials(_options = {})
    require 'manageiq/providers/telefonica/legacy/telefonica_event_monitor'
    TelefonicaEventMonitor.test_amqp_connection(event_monitor_options)
  rescue => err
    miq_exception = translate_exception(err)
    raise unless miq_exception

    _log.error("Error Class=#{err.class.name}, Message=#{err.message}")
    raise miq_exception
  end
  private :verify_amqp_credentials

  def verify_credentials(auth_type = nil, options = {})
    auth_type ||= 'default'

    raise MiqException::MiqHostError, "No credentials defined" if self.missing_credentials?(auth_type)

    options[:auth_type] = auth_type
    case auth_type.to_s
    when 'default' then verify_api_credentials(options)
    when 'amqp' then    verify_amqp_credentials(options)
    else;           raise "Invalid Telefonica Authentication Type: #{auth_type.inspect}"
    end
  end

  def required_credential_fields(_type)
    [:userid, :password]
  end

  def orchestration_template_validate(template)
    telefonica_handle.orchestration_service.templates.validate(:template => template.content)
    nil
  rescue Excon::Errors::BadRequest => bad
    JSON.parse(bad.response.body)['error']['message']
  rescue => err
    _log.error "template=[#{template.name}], error: #{err}"
    raise MiqException::MiqOrchestrationValidationError, err.to_s, err.backtrace
  end

  delegate :description, :to => :class
end
