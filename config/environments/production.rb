require "#{Rails.root}/lib/util/exception_notifier.rb"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  deliver_method = ENV.fetch('MAIL_DELIVERY_METHOD') { 'smtp' }.to_sym

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress CSS using a preprocessor.
  # harmony: true to enable ES6
  config.assets.js_compressor = Uglifier.new(harmony: true)
  # config.assets.css_compressor = :sass

  config.assets.compile = true
  config.assets.digest = true
  config.assets.check_precompiled_asset = false

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  config.action_cable.allowed_request_origins = [
    "https://#{ENV.fetch('FQDN') { 'nowhere.openpath.host' } }",
    "wss://#{ENV.fetch('FQDN') { 'nowhere.openpath.host' } }"
  ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  config.log_level = ENV.fetch('LOG_LEVEL') { 'info' }.to_sym

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "boston_hmis_#{Rails.env}"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = [I18n.default_locale]

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.sandbox_email_mode = false
  config.action_mailer.delivery_method = deliver_method
  config.action_mailer.default_url_options = { host: ENV['FQDN'], protocol: 'https'}
  if deliver_method == :smtp
    config.action_mailer.smtp_settings = {
      address: ENV['SMTP_SERVER'],
      port: 587,
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      authentication: :login,
      enable_starttls_auto: true,
    }
  end

  cache_ssl = (ENV.fetch('CACHE_SSL') { 'false' }) == 'true'
  cache_namespace = "#{ENV.fetch('CLIENT')}-#{Rails.env}-hmis"
  redis_config = Rails.application.config_for(:cache_store).merge({ expires_in: 8.hours, raise_errors: false, ssl: cache_ssl, namespace: cache_namespace})
  config.cache_store = :redis_cache_store, redis_config

  config.action_controller.perform_caching = true
  slack_config = Rails.application.config_for(:exception_notifier)[:slack]
  if slack_config.present?
    config.middleware.use(ExceptionNotification::Rack,
      slack: {
        webhook_url: slack_config[:webhook_url],
        channel: slack_config[:channel],
        pre_callback: proc { |opts, _notifier, _backtrace, _message, message_opts|
          ExceptionNotifierLib.insert_log_url!(message_opts)
        },
        additional_parameters: {
          mrkdwn: true,
          icon_url: slack_config[:icon_url]
        }
      }
    )
  end
end
