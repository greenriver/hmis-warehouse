# FIXME broke in rails 7
=begin
require File.expand_path('../../lib/util/notifier_config', __dir__)
include NotifierConfig
Rails.application.reloader.to_prepare do
  ActiveSupport::Notifications.subscribe('deprecation.rails') do |_name, _start, _finish, _id, payload|
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
=end
