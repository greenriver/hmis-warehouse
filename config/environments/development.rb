# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

I18n.config.available_locales = :en

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  # Don't force ssl for docker development
  config.force_ssl = false

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  config.action_cable.url = ENV.fetch('ACTION_CABLE_URL') { "wss://#{ENV['FQDN']}/cable" }
  config.action_cable.allowed_request_origins = [/.+/]
  config.hosts = [/.*/]

  # Do not eager load code on boot.
  config.eager_load = ENV.fetch('EAGER_LOAD', 'false') == 'true'

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  config.action_controller.perform_caching = true
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}",
    }
  else
    cache_ssl = (ENV.fetch('CACHE_SSL') { 'false' }) == 'true'
    redis_config = Rails.application.config_for(:cache_store).merge(
      {
        expires_in: 5.minutes,
        race_condition_ttl: 1.minute,
        ssl: cache_ssl,
        pool: { size: 10, timeout: 5 },
      },
    )
    config.cache_store = :redis_cache_store, redis_config
  end

  # it is helpful to turn off caching for development
  config.cache_store = :null_store if ENV.fetch('DISABLE_RAILS_CACHE', 'false') == 'true'

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = ENV.fetch('ACTIVE_STORAGE_SERVICE', 'minio').to_sym

  if ENV['SMTP_SERVER']
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.default_url_options = { host: ENV['FQDN'], protocol: 'http' }
    smtp_port = ENV.fetch('SMTP_PORT') { 587 }
    config.action_mailer.perform_deliveries = true
    if ENV['SMTP_USERNAME'] && ENV['SMTP_PASSWORD']
      config.action_mailer.smtp_settings = {
        address: ENV['SMTP_SERVER'],
        port: smtp_port,
        user_name: ENV['SMTP_USERNAME'],
        password: ENV['SMTP_PASSWORD'],
        authentication: :login,
        enable_starttls_auto: true,
      }
    else
      config.action_mailer.smtp_settings = {
        address: ENV['SMTP_SERVER'],
        port: smtp_port,
      }
    end
  else
    config.action_mailer.raise_delivery_errors = false
    config.action_mailer.delivery_method = ENV.fetch('DEV_MAILER') { :file }.to_sym
  end

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :raise

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false
  # Ensure development server doesn't serve precompiled assets, even if they exist
  config.assets.prefix = '/dev-assets'
  # config.action_controller.asset_host = ENV['FQDN']

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Devise requires a default URL
  config.action_mailer.default_url_options = { host: ENV['FQDN'], port: ENV['PORT'] }

  # don't need email sandbox with letter opener
  config.sandbox_email_mode = true

  # do gzip compressing in dev mode to simulate nginx config in production
  config.middleware.insert_after ActionDispatch::Static, Rack::Deflater

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker if ENV['ENABLE_EVENT_FS_CHECKER'] == '1'

  # Web console from outside of docker
  config.web_console.allowed_ips = ['172.16.0.0/12', '192.168.0.0/16', '10.0.0.0/8']

  console do
    if ENV['CONSOLE'] == 'pry'
      require 'pry-rails'
      config.console = Pry
    else
      require 'irb'
      config.console = IRB
    end
  end

  # haml config
  config.action_view.annotate_rendered_view_with_filenames = true

  # In order to fix the problem, the following options must be set.
  routes.default_url_options ||= {}
  routes.default_url_options[:script_name] = ''
  routes.default_url_options[:host] = ENV['FQDN']

  if ENV['DISABLE_AR_QUERY_TRACE'] != 'true'
    # this used to be the Marginalia gem, now built-in to rails
    config.active_record.query_log_tags_enabled = true
    config.active_record.query_log_tags = [
      :application,
      :controller,
      :action,
      :job,
      :source_location,
    ]
    ActiveRecord::QueryLogs.prepend_comment = false
  end

  # Raise error when a before_action's only/except options reference missing actions
  # FIXME: we'd like to turn this on but needs work
  # config.action_controller.raise_on_missing_callback_actions = true
end
