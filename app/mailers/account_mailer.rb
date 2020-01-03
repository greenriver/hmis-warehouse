###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class AccountMailer < Devise::Mailer
  default template_path: 'devise/mailer'

  ActionMailer::Base.register_interceptor CloudwatchEmailInterceptor if ENV['SES_MONITOR_OUTGOING_EMAIL'] == 'true'

  def invitation_instructions(record, action, opts = {})
    opts[:subject] = _('Boston DND Warehouse') + ': Account Activation Instructions'
    super
  end
end
