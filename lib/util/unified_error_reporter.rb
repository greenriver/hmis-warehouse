# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Unified error reporting: logs, optionally notifies Slack, and captures to Sentry.
# Decouples call sites from Sentry's API and makes the Slack opt-in explicit.
module UnifiedErrorReporter
  def self.call(exception, message = nil, slack_notifier: nil, sentry: true, context: {})
    msg = message || exception.message
    # ApplicationNotifier#ping already logs at info level, so skip the duplicate log
    # when a notifier is provided.
    Rails.logger.error(msg) unless slack_notifier
    slack_notifier&.ping(msg)
    Sentry.capture_exception_with_info(exception, msg, context) if sentry && Sentry.initialized?
  end
end
