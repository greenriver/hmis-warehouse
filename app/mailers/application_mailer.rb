###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ApplicationMailer < ActionMailer::Base
  default from: ENV['DEFAULT_FROM']
  layout 'mailer'

  ActionMailer::Base.register_interceptor SandboxEmailInterceptor if Rails.configuration.sandbox_email_mode

  ActionMailer::Base.register_interceptor CloudwatchEmailInterceptor if ENV['SES_MONITOR_OUTGOING_EMAIL'] == 'true'

  def self.prefix
    '[Warehouse]'
  end

  def prefix
    self.class.prefix
  end

  def provider_linked
    @user = params[:user]
    @provider_name = @user.provider.upcase

    mail(
      to: @user.email,
      subject: _("Sign in via #{@provider_name}"),
    )
  end

  def self.remove_prefix(subject)
    if subject.starts_with? prefix
      subject[prefix.length..].strip
    else
      subject
    end
  end
end
