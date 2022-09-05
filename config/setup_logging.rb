# Logging config in one place instead of six

class SetupLogging
  attr_accessor :config

  def initialize(config)
    self.config = config
  end

  def run!
    _configure_lograge

    if Rails.env.development?
      _development
    elsif Rails.env.test?
      _test
    elsif Rails.env.staging?
      _staging
    elsif Rails.env.production?
      _production
    else
      raise "Set up logging for your environment and try again"
    end
  end

  class OpenPathLogFormatter < ::Logger::Formatter
    def tagged(tag, &block)
      @tags ||= {}
      if tag.is_a?(Hash)
        @tags.merge!(tag)
      elsif tag.present?
        @tags.merge!({ tag => true })
      end
      block.call
    end

    def current_tags
      # We use our object ID here to avoid conflicting with other instances
      thread_key = @thread_key ||= "activesupport_tagged_logging_tags:#{object_id}"
      Thread.current[thread_key] ||= []
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
        application: 'BostonHmis::Application',
      }.reverse_merge(@tags).to_json + "\r\n"
    end
  end

  private

  def _configure_lograge
    config.lograge.logger = ActiveSupport::Logger.new($stdout)
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.base_controller_class = ['ActionController::Base']
    config.lograge.custom_options = ->(event) do
      {
        request_time: Time.current,
        application: Rails.application.class,
        server_protocol: event.payload[:server_protocol],
        host: event.payload[:host],
        remote_ip: event.payload[:remote_ip],
        ip: event.payload[:ip],
        session_id: event.payload[:session_id],
        user_id: event.payload[:user_id],
        process_id: Process.pid,
        pid: event.payload[:pid],
        request_id: event.payload[:request_id] || event.payload[:headers]['action_dispatch.request_id'],
        request_start: event.payload[:request_start],
        x_forwarded_for: event.payload[:x_forwarded_for],
        rails_env: Rails.env,
        exception: event.payload[:exception]&.first,
      }
    end
  end

  def _development
    config.log_level = ENV.fetch('LOG_LEVEL') { 'debug' }.to_sym

    if ENV['RAILS_LOG_TO_STDOUT'] == 'true'
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
    #config.logger.formatter = ActiveSupport::Logger::SimpleFormatter.new
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
