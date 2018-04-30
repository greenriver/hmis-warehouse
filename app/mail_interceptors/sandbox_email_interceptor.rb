class SandboxEmailInterceptor
  # TODO: list recipients who will always be BCC'd when application is running in sandbox mode
  RECIPIENTS = ENV['SANDBOX_RECIPIENTS']&.split(';') || []
  
  # TODO: list whitelisted email addresses here -- any other emails will only be BCC'd to the above
  # when this intercepter is in place
  ENV_WHITELIST = ENV['SANDBOX_WHITELIST']&.split(';') || []
  WHITELIST = (ENV_WHITELIST + RECIPIENTS).compact.map!(&:downcase)

  def self.delivering_email mail
    # mail.to = mail.to.to_a.select{|a| WHITELIST.include? a.downcase}
    # mail.cc = mail.cc.to_a.select{|a| WHITELIST.include? a.downcase}
    mail.bcc = RECIPIENTS
    unless Rails.env.production? || mail.delivery_method.is_a?(ApplicationMailer.delivery_methods[:db])
      mail.subject = "#{subject_warning} #{mail.subject.gsub(subject_warning, '')}"
      if mail.multipart?
        html_body = mail.html_part.body.to_s
        text_body = mail.text_part.body.to_s
        mail.html_part = html_body.sub('<body>', "<body><p>#{body_warning}</p>") unless html_body.include?(body_warning)
        mail.text_part = body_warning + "\n\n" +  text_body unless text_body.include?(body_warning)
      else
        mail.body = "#{body_warning} #{String(mail.body).sub(body_warning, '')}"
      end
    end
  end

  def self.subject_warning
    '[TRAINING]'
  end

  def self.body_warning
    "***This message is for training purposes only, the following information is fictitious and does not represent a real housing opportunity or homeless client.***"
  end

end
