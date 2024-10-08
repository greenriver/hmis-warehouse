# frozen_string_literal: true

require_relative '../../lib/util/git'

# ENV['SENTRY_DSN'] is reserved by Sentry and its use seems to prevent this initializer from being recognized.
# Hence, we use WAREHOUSE_SENTRY_DSN. Any other alternate key should also be fine.

sentry_dsn = ENV['WAREHOUSE_SENTRY_DSN'].presence
if sentry_dsn
  Sentry.init do |config|
    config.dsn = sentry_dsn
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    trace_rate = ENV['SENTRY_PERFORMANCE_TRACE_RATE'].presence
    # enable performance monitoring on QA
    trace_rate ||= '1.0' if Rails.env.staging? && ENV['CLIENT'] == 'qa_hmis'
    trace_rate = trace_rate.to_f
    config.traces_sample_rate = trace_rate if trace_rate.positive?

    config.enabled_environments = ['production', 'staging', 'development']
    config.environment = Rails.env

    if config.enabled_environments.include?(config.environment) && config.dsn.to_s.match?(/sentry\.io/)
      Rails.logger.info "Enabling Sentry for environment #{config.environment}" unless ENV['QUIET_SENTRY_ENTRY'].present?
    else
      Rails.logger.error "Cannot enable Sentry for environment #{config.environment}"
    end

    config.release = Git.revision

    # Replacement for Raven's: `config.sanitize_fields`
    # See: https://stackoverflow.com/questions/68867756/missing-piece-in-sentry-raven-to-sentry-ruby-guide
    # And: https://github.com/getsentry/sentry-ruby/issues/1140
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters - [:email])
    config.before_send = ->(event, _hint) do
      filter.filter(event.to_hash)
    end
  end

  cluster_type =
    if ENV['ECS'] == 'true' && ENV['EKS'] != 'true'
      'ecs'
    elsif ENV['ECS'] != 'true' && ENV['EKS'] == 'true'
      'eks'
    else
      'unknown'
    end

  Sentry.configure_scope do |scope|
    log_stream_url = ENV.fetch('LOG_STREAM_URL', '[LOG_STREAM_URL not found]')
    scope.set_context('extra', { log_stream_url: log_stream_url })
    scope.set_tags(
      {
        client: ENV.fetch('CLIENT', '[CLIENT not found]'),
        container_variant: ENV.fetch('CONTAINER_VARIANT', '[CONTAINER_VARIANT not found]'),
        target_group_name: ENV.fetch('TARGET_GROUP_NAME', '[TARGET_GROUP_NAME not found]'),
        dev_user: (ENV.fetch('SENTRY_DEV_USER', '[DEV_USER not found]') if Rails.env.development?),
        cluster_type: cluster_type,
      }.compact,
    )
  end
end

module Sentry
  module_function

  def capture_exception_with_info(error, msg, info = {})
    return unless Sentry.initialized?

    Sentry.with_scope do |scope|
      scope.set_context(
        'errorInfo',
        {
          message: msg,
        }.merge(info || {}),
      )
      Sentry.capture_exception(error)
    end
  end
end
