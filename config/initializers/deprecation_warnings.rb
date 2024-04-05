Rails.application.reloader.to_prepare do
  include NotifierConfig
  ActiveSupport::Notifications.subscribe('deprecation.rails') do |_name, _start, _finish, _id, payload|
    puts "what: #{[name].inspect}"
    setup_notifier('DeprecationWarning')
    @notifier.ping(
      payload[:message],
      info: {
        error_class: 'deprecation_warning',
        error_message: payload[:message],
        backtrace: payload[:callstack],
      },
    )
  end
end
