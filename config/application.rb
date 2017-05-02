require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BostonHmis
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.action_controller.include_all_helpers = false

    config.active_record.schema_format = :sql

    config.active_job.queue_adapter = :delayed_job

    config.generators do |generate|
      generate.helper false
      generate.assets false
      generate.test_framework false
    end

    config.lograge.enabled = true
    config.lograge.custom_options = ->(event) do
      {
        server_protocol: event.payload[:server_protocol],
        remote_ip: event.payload[:remote_ip],
        session_id: event.payload[:session_id],
        user_id: event.payload[:user_id],
        pid: event.payload[:pid],
        request_id: event.payload[:request_id],
        request_start: event.payload[:request_start]
      }
    end

    # additional library paths
    config.autoload_paths << Rails.root.join('lib', 'util')

    # force all requests over ssl by default
    config.force_ssl = true
  end
end
