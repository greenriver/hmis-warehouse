###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# TODO: this needs to be cleaned up for oauth2
class AccountMailer < ApplicationMailer
  ActionMailer::Base.register_interceptor CloudwatchEmailInterceptor if ENV['SES_MONITOR_OUTGOING_EMAIL'] == 'true'

  def invitation_instructions(record, action, opts = {})
    opts[:subject] = Translation.translate('Open Path HMIS Warehouse') + ': Account Activation Instructions'
    super
  end
end
