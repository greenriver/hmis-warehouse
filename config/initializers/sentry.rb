# frozen_string_literal: true

# ENV['SENTRY_DSN'] is reserved by Sentry and its use seems to prevent this initializer from being recognized.
# Hence, we use WAREHOUSE_SENTRY_DSN. Any other alternate key should also be fine.
if ENV['WAREHOUSE_SENTRY_DSN'].present?
  Sentry.init do |config|
    config.dsn = ENV['WAREHOUSE_SENTRY_DSN']
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    config.enabled_environments = %w[production staging development] # Remove development when dev is done.
    config.environment = Rails.env

    if config.enabled_environments.include?(config.environment) && config.dsn.to_s.match?(/sentry\.io/)
      Rails.logger.info "Enabling Sentry for environment #{config.environment}"
    else
      Rails.logger.error "Cannot enable Sentry for environment #{config.environment}"
    end

    config.release = File.read('REVISION') if File.exist?('REVISION')

    # Replacement for Raven's: `config.sanitize_fields`
    # See: https://stackoverflow.com/questions/68867756/missing-piece-in-sentry-raven-to-sentry-ruby-guide
    # And: https://github.com/getsentry/sentry-ruby/issues/1140
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    config.before_send = ->(event, hint) do
      filter.filter(event.to_hash)
    end
  end
end

Sentry.configure_scope do |scope|
  log_stream_url = ENV.fetch('LOG_STREAM_URL', '[no log stream url found]')
  scope.set_context('extra', {
    log_stream_url: log_stream_url
  })
end
