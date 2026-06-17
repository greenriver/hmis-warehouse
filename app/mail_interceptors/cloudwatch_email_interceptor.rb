###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CloudwatchEmailInterceptor
  def self.delivering_email(message)
    message.headers(
      'X-SES-CLIENT' => ENV.fetch('CLIENT') { 'UnknownClient' },
      'X-SES-APP' => 'Warehouse',
      'X-SES-CONFIGURATION-SET' => ENV.fetch('SES_CONFIG_SET') { 'OpenPathConfigSet' },
      'X-SES-ENVIRONMENT' => Rails.env,
    )
  end
end
