###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ApplicationNotifier < Slack::Notifier

  def ping(message, options={})
    return unless @endpoint&.host

    # Rate limit pings because Slack wants us to
    sleep(0.7)
    begin
      super(message, options)
    rescue OpenSSL::SSL::SSLError # Ignore some intermittant errors so they don't break the app
      Rails.logger.error('Failed to send slack')
    rescue Slack::Notifier::APIError
      sleep(3)
      Rails.logger.error('Failed to send slack')
    end
  end
end
