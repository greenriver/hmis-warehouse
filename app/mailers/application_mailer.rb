class ApplicationMailer < ActionMailer::Base
  default from: ENV['DEFAULT_FROM']
  layout 'mailer'

  if Rails.configuration.sandbox_email_mode
    ActionMailer::Base.register_interceptor SandboxEmailInterceptor
  end
end
