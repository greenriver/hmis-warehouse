Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Don't force ssl for docker development
  config.force_ssl = false

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
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

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    cache_ssl = (ENV.fetch('CACHE_SSL') { 'false' }) == 'true'
    config.cache_store = :redis_store, Rails.application.config_for(:cache_store), { expires_in: 2.minutes, raise_errors: false, ssl: cache_ssl, namespace: :hmis }
  end

  if ENV['SMTP_SERVER'] && ENV['SMTP_USERNAME'] && ENV['SMTP_PASSWORD']
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.default_url_options = { host: ENV['FQDN'], protocol: 'http'}
    config.action_mailer.smtp_settings = {
      address: ENV['SMTP_SERVER'],
      port: 587,
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      authentication: :login,
      enable_starttls_auto: true,
    }
  else
    # Don't care if the mailer can't send.
    config.action_mailer.raise_delivery_errors = false

    config.action_mailer.delivery_method = :letter_opener
  end

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true
  # config.action_controller.asset_host = ENV['FQDN']

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
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
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
