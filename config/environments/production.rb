Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.serve_static_files = true
  config.assets.js_compressor = :uglifier
  config.assets.compile = true
  config.assets.digest = true
  config.force_ssl = false
  config.log_level = :info
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
  config.active_record.dump_schema_after_migration = false
  config.sandbox_email_mode = false
  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.default_url_options = { host: ENV['HOSTNAME'], protocol: 'https'}
  config.action_mailer.smtp_settings = {
    address: ENV['SES_SMTP_SERVER'],
    port: 587,
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: :login,
    enable_starttls_auto: true,
  }
  config.cache_store = :redis_store, Rails.application.config_for(:cache_store), { expires_in: 8.hours }
  config.action_controller.perform_caching = true
  config.middleware.use ExceptionNotification::Rack,
    :slack => {
      :webhook_url => Rails.application.config_for(:exception_notifier)['slack']['webhook_url'],
      :channel => Rails.application.config_for(:exception_notifier)['slack']['channel'],
      :additional_parameters => {
        :mrkdwn => true,
        :icon_url => Rails.application.config_for(:exception_notifier)['slack']['icon_url']
      }
    }
end
