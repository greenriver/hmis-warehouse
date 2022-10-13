# frozen_string_literal: true

if ENV['SENTRY_DSN'].present?
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    # config.enabled_environments = %w[production staging]
    config.environment = Rails.env

    # if config.enabled_environments.include?(config.environment) && config.dsn.to_s.match?(/sentry\.io/)
    #   Rails.logger.info 'Looks like sentry is enabled'
    # else
    #   Rails.logger.info 'Looks like sentry is NOT enabled'
    # end

    config.release = File.read('REVISION') if File.exist?('REVISION')

    # Replacement for Raven's: `config.sanitize_fields`
    # See: https://stackoverflow.com/questions/68867756/missing-piece-in-sentry-raven-to-sentry-ruby-guide
    # And: https://github.com/getsentry/sentry-ruby/issues/1140
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    config.before_send = ->(event, hint) do
      filter.filter(event.to_hash)
    end

    # config.excluded_exceptions += ['ActionController::UnknownHttpMethod']
    # config.traces_sample_rate = 0
  end
end
