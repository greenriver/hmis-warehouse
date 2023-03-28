ActiveSupport::Notifications.subscribe('deprecation.rails') do |name, start, finish, id, payload|
  include NotifierConfig
  puts 'HERE'
  setup_notifier('DeprecationWarning')
  @notifier.ping(
    payload[:message],
    info: {
      error_class:   'deprecation_warning',
      error_message: payload[:message],
      backtrace:     payload[:callstack],
    },
  )
end
