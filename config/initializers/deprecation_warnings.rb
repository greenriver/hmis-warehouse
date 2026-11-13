###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

Rails.application.reloader.to_prepare do
  class DeprecationWarningInitializerNotifier
    include NotifierConfig
    def perform
      setup_notifier('DeprecationWarning')
      ActiveSupport::Notifications.subscribe('deprecation.rails') do |_name, _start, _finish, _id, payload|
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
  end
  DeprecationWarningInitializerNotifier.new.perform
end
