class ApplicationMailer < ActionMailer::Base
  default from: ENV['DEFAULT_FROM']
  layout 'mailer'

  if Rails.configuration.sandbox_email_mode
    ActionMailer::Base.register_interceptor SandboxEmailInterceptor
  end

  def self.prefix
    '[Warehouse]'
  end

  def prefix
    self.class.prefix
  end

  def self.remove_prefix(subject)
    if subject.starts_with? prefix
      subject[prefix.length..-1].strip
    else
      subject
    end
  end
end
