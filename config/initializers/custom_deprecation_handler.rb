# frozen_string_literal: true

require 'singleton'
require 'warning'
Warning[:deprecated] = true

class CustomDeprecationHandler
  include Singleton
  attr_reader :cache

  def initialize
    @cache = ActiveSupport::Cache::MemoryStore.new
  end

  def call(message:, backtrace: nil)
    error = StandardError.new(message)
    begin
      error.set_backtrace(backtrace) if backtrace
    rescue TypeError # rubocop:disable Lint/SuppressedException
    end
    key = Digest::MD5.hexdigest(error.full_message)
    # rate limit warnings
    cache.fetch(key, expires_in: 1.minute) do
      Sentry.capture_exception(error) do |scope|
        scope.set_level('warning')
      end
      message # cached result we don't care about
    end
  end
end

# rails deprecations are logged
case Rails.configuration.active_support.deprecation
when :notify
  ActiveSupport::Notifications.subscribe('deprecation.rails') do |_name, _start, _finish, _event_id, payload|
    CustomDeprecationHandler.instance.
      call(message: payload[:message], backtrace: payload[:callstack])
  end
when :raise
  TodoOrDie('Remove deprecated date/time.to_s', by: '2024-07-01')
  # we don't want CI tests to fail because of date.to_s deprecations. Remove this once we have fixed deprecations
  if Rails.env.test?
    ActiveSupport::Deprecation.behavior = lambda do |message, stack, deprecation_horizon, gem_name|
      ActiveSupport::Deprecation::DEFAULT_BEHAVIORS[:raise].call(message, stack, deprecation_horizon, gem_name) unless message =~ /RAILS_DISABLE_DEPRECATED_TO_S_CONVERSION/
    end
  end
end

# ruby deprecations are logged or raised in development (ymmv)
Warning.process do |message|
  if Rails.env.development?
    :raise
  else
    CustomDeprecationHandler.instance.
      call(message: message, backtrace: caller(6))
    :default
  end
end
