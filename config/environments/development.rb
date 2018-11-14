Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.delivery_method = :letter_opener

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true
  # config.action_controller.asset_host = ENV['HOSTNAME']

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Duplicate Production asset handling
  # config.assets.debug = false
  # config.serve_static_files = true
  config.assets.js_compressor = Uglifier.new(harmony: true)
  # config.assets.compile = true
  # config.assets.digest = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Devise requires a default URL
  config.action_mailer.default_url_options = { host: ENV['HOSTNAME'], port: ENV['PORT'] }

  # don't need email sandbox with letter opener
  config.sandbox_email_mode = true

  # make the development log noisy so you can see request parameters, views rendered, etc.
  config.lograge.enabled = false

  config.force_ssl = true

  config.cache_store = ActiveSupport::Cache::RedisStore.new(
    Rails.application.config_for(:cache_store).merge(expires_in: 8.hours)
  )
  config.cache_store.logger = Logger.new(Rails.root.join("log/cache.log"))
  config.cache_store.logger.level = Logger::DEBUG


  # do gzip compressing in dev mode to simulate nginx config in production
  config.middleware.insert_after ActionDispatch::Static, Rack::Deflater


  # config.middleware.use ExceptionNotification::Rack,
  #   :slack => {
  #     :webhook_url => Rails.application.config_for(:exception_notifier)['slack']['webhook_url'],
  #     :channel => Rails.application.config_for(:exception_notifier)['slack']['channel'],
  #     :additional_parameters => {
  #       :mrkdwn => true,
  #       :icon_url => Rails.application.config_for(:exception_notifier)['slack']['icon_url']
  #     }
  #   }
end
