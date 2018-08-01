Rails.application.configure do
  deliver_method = ENV['MAIL_DELIVERY_METHOD'].to_sym
  slack_config = Rails.application.config_for(:exception_notifier)['slack']

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
  config.action_mailer.delivery_method = deliver_method
  config.action_mailer.default_url_options = { host: ENV['HOSTNAME'], protocol: 'https'}
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
  config.cache_store = :redis_store, Rails.application.config_for(:cache_store), { expires_in: 8.hours, raise_errors: false, ssl: cache_ssl }

  config.action_controller.perform_caching = true
  if slack_config.present?
    config.middleware.use(ExceptionNotification::Rack,
      :slack => {
        :webhook_url => slack_config['webhook_url'],
        :channel => slack_config['channel'],
        :additional_parameters => {
          :mrkdwn => true,
          :icon_url => slack_config['icon_url']
        }
      }
    )
  end
end
