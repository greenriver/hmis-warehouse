require_relative 'boot'
require_relative "../app/logger/log_formatter.rb"

require 'rails/all'
require "active_record_extended"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative '../lib/util/id_protector'

module BostonHmis
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.autoloader = :classic
    config.autoload_paths << Rails.root.join('lib/devise')

    # ActionCable
    config.action_cable.mount_path = "/cable"
    config.action_cable.url = ENV.fetch('ACTION_CABLE_URL') { "wss://#{ENV['FQDN']}/cable" }

    Rails.application.config.active_record.belongs_to_required_by_default = true
    config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time]

    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = ENV.fetch('TIMEZONE') { 'America/New_York' }

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    config.action_controller.include_all_helpers = false

    config.active_record.schema_format = ENV.fetch('SCHEMA_FORMAT') { 'sql' }.to_sym

    config.active_job.queue_adapter = :delayed_job

    config.generators do |generate|
      generate.helper false
      generate.assets false
      generate.test_framework :rspec
    end

    config.lograge.enabled = true
    config.lograge.logger = ActiveSupport::Logger.new(STDOUT)
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
    config.logger = ActiveSupport::Logger.new(STDOUT)
    config.logger.formatter = LogFormatter.new

    # default to not be sandbox email mode
    config.sandbox_email_mode = false

    # additional library paths
    config.eager_load_paths << Rails.root.join('lib', 'util')

    # serve error pages from the Rails app itself
    # rather than using static error pages in public/.
    config.exceptions_app = self.routes

    config.middleware.use Rack::Attack # needed pre rails 5.1
    config.middleware.use IdProtector

    # FIXME: required to make forms in pjax modals work
    config.action_controller.per_form_csrf_tokens = false

    # Extension points
    config.sub_populations = {}
    config.census = {}
    config.monthly_reports = {}
    config.hud_reports = {}
    config.hmis_importers = []
    config.hmis_exporters = []
    config.synthetic_event_types = []
    config.synthetic_assessment_types = []
    config.patient_dashboards = []
    config.hmis_migrations = {}
    config.hmis_data_lake = nil
    config.custom_imports = []
  end
end
