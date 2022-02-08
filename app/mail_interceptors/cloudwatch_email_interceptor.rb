###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
