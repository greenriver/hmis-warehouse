# frozen_string_literal: true

# Logging config in one place instead of six

class SetupLogging
  attr_accessor :config

  STANDARD_TAGS = {
    gr_client: 'openpath',

    # If there are more apps, these would differ. Some other examples:
    # airflow, superset, or other microservices that would conceivably run on
    # the same cluster and/or have some close relationship with the main application.
    app: 'warehouse',

    # Some Green River clients have multiple tenants running the same general
    # code (but with different databases or environment variables)
    tenant: ENV.fetch('CLIENT', 'unknown-client-set-CLIENT-env-var'),
  }.freeze

  def initialize(config)
    self.config = config
  end

  def run!
    _configure_lograge

    if Rails.env.development? || ENV['TEST_DEVELOPMENT_LOGGING_CONFIG'] == 'true'
      _development
    elsif Rails.env.test?
      _test
    elsif Rails.env.staging? || ENV['TEST_STAGING_LOGGING_CONFIG'] == 'true'
      _staging
    elsif Rails.env.production?
      _production
    else
      raise 'Set up logging for your environment and try again'
    end
  end

  class OpenPathLogFormatter < ::Logger::Formatter
    def tagged(*args, &block)
      tags = Array.wrap(args).flatten
      @tags = {}
      if tags[0].is_a?(Hash)
        tags.each do |t|
          @tags.merge!(t)
        end
      elsif tags.present?
        @tags.merge!(tags.map { |x| [x, true] }.to_h)
      end

      result = block.call

      # Reset tags so Rails.logger.info('msg') won't be tagged with the last tag
      clear_tags!

      # This method is actually rack middleware (at least in some contexts). It
      # needs to pass along the block call.
      result
    end

    def current_tags
      # We use our object ID here to avoid conflicting with other instances
      thread_key = @thread_key ||= "activesupport_tagged_logging_tags:#{object_id}"
      Thread.current[thread_key] ||= @tags&.keys || []
    end

    def clear_tags!
      @tags = {}
    end

    def call(severity, time, program_name, message)
      @tags ||= {}
      message = '' if message.blank?
      severity = '' if message.blank?
      program_name = '' if program_name.blank?

      {
        level: severity,
        progname: program_name,
        message: message,
        rails_env: Rails.env,
        request_time: time,
        # application: 'BostonHmis::Application',
      }.merge(STANDARD_TAGS).reverse_merge(@tags).to_json + "\r\n"
    end
  end

  private

  def _configure_lograge
    config.lograge.logger = ActiveSupport::Logger.new($stdout)
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.base_controller_class = ['ActionController::Base']
    config.lograge.custom_options = ->(event) do
      payload = event.payload || raise('Lograge event payload missing')
      request = payload[:request]
      headers_env = request&.headers&.env || {}

      ip_data = payload.slice(:remote_ip, :ip, :remote_addr, :x_forwarded_for)

      server_protocol = request&.protocol.presence || payload[:server_protocol]
      host = request&.host.presence || payload[:host]
      request_id = payload[:request_id] || payload.fetch(:headers, {})['action_dispatch.request_id']
      trace_id = headers_env['HTTP_X_AMZN_TRACE_ID']

      {
        request_time: Time.current, # Server timestamp (trusted)
        server_protocol: server_protocol, # From Rack env; trusted when present
        host: host, # From Host header; untrusted
        session_id: payload[:session_id], # Rack session; trusted
        user_id: payload[:user_id], # App assigned; trusted
        pid: payload[:pid], # Raw payload PID; trusted if present
        request_id: request_id, # Rails request UUID; trusted
        request_start: payload[:request_start], # Header supplied; untrusted
        rails_env: Rails.env, # Deployment environment; trusted
        exception: payload[:exception]&.first, # Raised error class; trusted
        x_amzn_trace_id: trace_id, # AWS trace header; untrusted
      }.merge(ip_data).merge(STANDARD_TAGS)
    end
  end

  def _development
    config.log_level = ENV.fetch('LOG_LEVEL') { 'debug' }.to_sym

    if ENV['RAILS_LOG_TO_STDOUT'] == 'true' || ENV['LOG_STD'] == 'true'
      config.logger = _tagged(ActiveSupport::Logger.new($stdout))
    else
      config.logger = _tagged(ActiveSupport::Logger.new("log/#{Rails.env}.log"))
    end

    if ENV['LOGRAGE'] == 'true'
      config.logger.formatter = OpenPathLogFormatter.new
      config.lograge.enabled = true
    else
      config.lograge.enabled = false
    end
  end

  def _test
    config.lograge.enabled = false
    config.log_level = ENV.fetch('LOG_LEVEL') { 'info' }.to_sym
    config.logger = _tagged ActiveSupport::Logger.new("log/#{Rails.env}.log")
  end

  def _staging
    # They're the same
    _production
  end

  def _production
    config.log_level = ENV.fetch('LOG_LEVEL') { 'info' }.to_sym
    config.logger = _tagged(ActiveSupport::Logger.new($stdout))
    config.logger.formatter = OpenPathLogFormatter.new
    config.lograge.enabled = true
  end

  def _tagged(logger)
    ActiveSupport::TaggedLogging.new(logger)
  end
end
