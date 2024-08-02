require_relative 'boot'

require 'rails/all'
require 'active_record_extended'

# The env var is the same as config.active_support.disable_to_s_conversion = true but impacts driver initializers that load before this app config block
#   * Note, we still use the deprecated behavior for date/time. It's preserved in config/initializers/legacy_rails_conversions.rb
ENV['RAILS_DISABLE_DEPRECATED_TO_S_CONVERSION'] = 'true'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative '../lib/util/id_protector'

module BostonHmis
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.autoload_paths << Rails.root.join('lib', 'devise')

    # ActionCable
    config.action_cable.mount_path = '/cable'
    config.action_cable.url = ENV.fetch('ACTION_CABLE_URL') { "wss://#{ENV['FQDN']}/cable" }

    Rails.application.config.active_record.belongs_to_required_by_default = true
    # https://discuss.rubyonrails.org/t/cve-2022-32224-possible-rce-escalation-bug-with-serialized-columns-in-active-record/81017
    # config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time]
    config.active_record.use_yaml_unsafe_load = true

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
    config.action_mailer.deliver_later_queue_name = :mailers

    config.active_storage.variant_processor = :mini_magick
    config.active_storage.variable_content_types = ['image/png', 'image/gif', 'image/jpeg', 'image/tiff', 'image/bmp', 'image/webp', 'image/avif', 'image/heic', 'image/heif']

    # GraphQL config
    config.graphql.parser_cache = true

    config.generators do |generate|
      generate.helper false
      generate.assets false
      generate.test_framework :rspec
    end

    if ENV['RAILS_DISABLE_CUSTOM_LOGGING'].blank?
      require_relative('setup_logging')
      setup_logging = SetupLogging.new(config)
      setup_logging.run!
    end
    config.colorize_logging = false if ENV['RAILS_DISABLE_COLORIZE_LOGGING'].present?

    # default to not be sandbox email mode
    config.sandbox_email_mode = false

    # additional library paths
    config.eager_load_paths << Rails.root.join('lib', 'util')
    config.eager_load_paths << Rails.root.join('lib', 'devise')

    # serve error pages from the Rails app itself
    # rather than using static error pages in public/.
    config.exceptions_app = routes

    # FIXME: required to make forms in pjax modals work
    config.action_controller.per_form_csrf_tokens = false

    if Rails.env.production? || Rails.env.staging?
      # FIXME this IP should be in environment specific configuration
      trusted_proxy = IPAddr.new('44.206.34.193')
      config.action_dispatch.trusted_proxies = ActionDispatch::RemoteIp::TRUSTED_PROXIES + [IPAddr.new(trusted_proxy]
    end

    # Extension points
    config.sub_populations = {}
    config.census = {}
    config.monthly_reports = {}
    config.hud_reports = {}
    config.hmis_importers = []
    config.hmis_exporters = []
    config.synthetic_event_types = []
    config.synthetic_assessment_types = []
    config.synthetic_youth_education_status_types = []
    config.patient_dashboards = []
    config.hmis_migrations = {}
    config.hmis_data_lake = nil
    config.custom_imports = []
    config.supplemental_enrollment_importers = {}
    config.help_links = []
    config.location_processors = []
    config.queued_tasks = {}

    # FIX for service history services change
    config.queued_tasks[:service_history_services_materialized_rebuild_and_process] = -> do
      GrdaWarehouse::ServiceHistoryServiceMaterialized.rebuild!
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts
    end

    # Fix for chronic calculator
    # Previously, imported data where the enrollment was in a literally homeless project
    # where the client would accumulate days between entry & exit that counted toward
    # "Chronically Homeless at start", the current date was used to make the chronic
    # determination instead of the exit date
    config.queued_tasks[:ch_enrollment_exited_rebuild] = -> do
      # Invalidate the calculation for any enrollment with an exit date
      # that was previously marked chronic at entry
      GrdaWarehouse::ChEnrollment.joins(enrollment: :exit).
        where(chronically_homeless_at_entry: true).
        update_all(processed_as: nil)
      GrdaWarehouse::ChEnrollment.maintain!
    end
  end
end
