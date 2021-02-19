require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Don't force ssl for docker development
  config.force_ssl = false

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = true

    cache_ssl = (ENV.fetch('CACHE_SSL') { 'false' }) == 'true'
    cache_namespace = "#{ENV.fetch('CLIENT')}-#{Rails.env}-hmis"
    config.cache_store = :redis_store, Rails.application.config_for(:cache_store), { expires_in: 5.minutes, raise_errors: false, ssl: cache_ssl, namespace: cache_namespace}
  end

  # You're using a cache store that doesn't support native cache versioning.
  # Your best option is to upgrade to a newer version of ActiveSupport::Cache::RedisStore
  # that supports cache versioning (ActiveSupport::Cache::RedisStore.supports_cache_versioning? #=> true).

  # Next best, switch to a different cache store that does support cache versioning:
  # https://guides.rubyonrails.org/caching_with_rails.html#cache-stores.

  # To keep using the current cache store, you can turn off cache versioning entirely:
  config.active_record.cache_versioning = false

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local


  if ENV['SMTP_SERVER']
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.default_url_options = { host: ENV['FQDN'], protocol: 'http'}
    smtp_port = ENV.fetch('SMTP_PORT'){ 587 }
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
    # Don't care if the mailer can't send.
    config.action_mailer.raise_delivery_errors = false

    config.action_mailer.delivery_method = ENV.fetch("DEV_MAILER") { :file }.to_sym
  end

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false
  # config.action_controller.asset_host = ENV['FQDN']

  # Suppress logger output for asset requests.
  config.assets.quiet = false

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Devise requires a default URL
  config.action_mailer.default_url_options = { host: ENV['FQDN'], port: ENV['PORT'] }

  # don't need email sandbox with letter opener
  config.sandbox_email_mode = true

  # make the development log noisy so you can see request parameters, views rendered, etc.
  config.lograge.enabled = false

  # do gzip compressing in dev mode to simulate nginx config in production
  config.middleware.insert_after ActionDispatch::Static, Rack::Deflater

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  if ENV['DISABLE_EVENT_FS_CHECKER'] != '1'
    config.file_watcher = ActiveSupport::EventedFileUpdateChecker
  end

  # Web console from outside of docker
  config.web_console.allowed_ips = ['172.16.0.0/12', '192.168.0.0/16']

  # In order to fix the problem, the following options must be set.
  routes.default_url_options ||= {}
  routes.default_url_options[:script_name]= ''

  # allow requests to development hostname. This is a new feature on Rails 6
  # "Host Authorization, (a) new middleware included in Rails to prevent against DNS rebinding attacks"
  # https://www.fngtps.com/2019/rails6-blocked-host/
  config.hosts << "hmis-warehouse.dev.test"
end
