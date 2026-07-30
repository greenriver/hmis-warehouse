###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'
require 'active_record_extended'

# The env var is the same as config.active_support.disable_to_s_conversion = true but impacts driver initializers that load before this app config block
#   * Note, we still use the deprecated behavior for date/time. It's preserved in config/initializers/legacy_rails_conversions.rb
ENV['RAILS_DISABLE_DEPRECATED_TO_S_CONVERSION'] = 'true'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative '../lib/auth_method'
require_relative '../lib/util/id_protector'
require_relative '../lib/util/rails_trusted_proxies_config'

# common route concerns, included here to avoid class loader issues due to "drivers" load order in dev mode
require_relative '../lib/hud_reports/route_concerns'

module OpenPath
  class Application < Rails::Application
    require_relative '../lib/rails_drivers'

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Continue to use config/secrets.yml. This is deprecated in rails > 7.0 but we don't want to move to
    # encrypted credentials, it's not appropriate for an open-source project
    if File.exist?(Rails.root.join('config', 'secrets.yml'))
      config.secrets = config_for(:secrets) # loads from config/secrets.yml
      if config.secrets.present?
        config.secret_key_base = config.secrets[:secret_key_base]

        def secrets
          config.secrets
        end
      end
    end

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    # config.autoload_lib(ignore: ['assets', 'tasks'])

    config.add_autoload_paths_to_load_path = false
    config.autoload_paths << Rails.root.join('lib', 'devise')

    # ActionCable
    config.action_cable.mount_path = '/cable'
    config.action_cable.url = ENV.fetch('ACTION_CABLE_URL') { "wss://#{ENV['FQDN']}/cable" }

    ENV['TRUSTED_PROXIES'].presence&.then do |trusted_proxies|
      parsed = RailsTrustedProxiesConfig.parse_csv(trusted_proxies)
      # if we are adding custom trusted proxies, we need to include the default addrs
      config.action_dispatch.trusted_proxies = (ActionDispatch::RemoteIp::TRUSTED_PROXIES + parsed) if parsed
    end

    Rails.application.config.active_record.belongs_to_required_by_default = true
    # https://discuss.rubyonrails.org/t/cve-2022-32224-possible-rce-escalation-bug-with-serialized-columns-in-active-record/81017
    # config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time]
    config.active_record.use_yaml_unsafe_load = true

    # ActiveRecord encryption backs devise-two-factor 6.x's `otp_secret` column (new and
    # re-enrolled 2FA secrets). Existing secrets remain in encrypted_otp_secret* and are
    # read via User#legacy_otp_secret. Keys are derived from the existing ENCRYPTION_KEY so
    # no new secrets need provisioning; set the AR_ENCRYPTION_* env vars to override.
    if (encryption_root = ENV['ENCRYPTION_KEY']).present?
      derive_ar_encryption_key = lambda do |label, override_env|
        ENV[override_env].presence || OpenSSL::KDF.pbkdf2_hmac(
          encryption_root,
          salt: "ar-encryption:#{label}",
          iterations: 2**16,
          length: 32,
          hash: 'sha256',
        ).unpack1('H*')
      end
      config.active_record.encryption.primary_key = derive_ar_encryption_key.call('primary_key', 'AR_ENCRYPTION_PRIMARY_KEY')
      config.active_record.encryption.deterministic_key = derive_ar_encryption_key.call('deterministic_key', 'AR_ENCRYPTION_DETERMINISTIC_KEY')
      config.active_record.encryption.key_derivation_salt = derive_ar_encryption_key.call('key_derivation_salt', 'AR_ENCRYPTION_KEY_DERIVATION_SALT')
    end

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
    # Disable Active Storage routes
    config.active_storage.draw_routes = false

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

    # Replace rails_drivers gem autoloading — mirrors what the gem's Railtie did
    driver_app_components = ['models', 'controllers', 'mailers', 'helpers', 'jobs', 'graphql'].freeze

    Dir[root.join('drivers', '*', 'app')].each do |driver_app|
      driver_app_components.each do |component|
        component_dir = File.join(driver_app, component)
        next unless File.directory?(component_dir)

        # autoload_paths: the catalog of where things can be found (lazy-load)
        config.autoload_paths << component_dir
        # eager_load_paths: the subset Rails loads proactively at boot time
        config.eager_load_paths << component_dir
      end
    end

    Dir[root.join('drivers', '*', 'lib')].each do |driver_lib|
      next unless File.directory?(driver_lib)

      config.autoload_paths << driver_lib
      tasks_dir = File.join(driver_lib, 'tasks')
      Rails.autoloaders.main.ignore(tasks_dir) if File.directory?(tasks_dir)
    end

    # serve error pages from the Rails app itself
    # rather than using static error pages in public/.
    config.exceptions_app = routes

    # FIXME: required to make forms in pjax modals work
    config.action_controller.per_form_csrf_tokens = false

    # Maintain Rails 7.0 behavior for specific settings
    config.active_record.before_committed_on_all_records = false # Keep due to uploader test issues
    config.active_record.default_column_serializer = YAML # Keep historic behavior

    # Extension points
    config.sub_populations = {}
    config.census = {}
    config.monthly_reports = {}
    config.hud_reports = {}
    config.hmis_exporters = []
    config.synthetic_event_types = []
    config.synthetic_assessment_types = []
    config.synthetic_youth_education_status_types = []
    config.patient_dashboards = []
    config.hmis_migrations = {}
    config.hmis_data_lakes = {}

    config.custom_imports = []
    config.supplemental_enrollment_importers = {}
    config.help_links = []
    config.location_processors = []
    config.queued_tasks = {}
    config.report_archival_types = []

    initializer 'load_driver_routes', before: :add_routing_paths, after: :bootstrap_hook do |app|
      Dir[root.join('drivers', '*', 'config', 'routes.rb')].sort.each do |route_path|
        app.routes_reloader.paths.unshift(route_path)
      end
    end

    initializer 'load_driver_feature_initializers', after: :load_config_initializers do
      Dir[root.join('drivers', '**', 'config', 'initializers', '**', '*.rb')].sort.each do |path|
        load path
      end
    end
  end
end
