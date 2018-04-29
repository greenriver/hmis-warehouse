class SandboxEmailInterceptor
  # TODO: list recipients who will always be BCC'd when application is running in sandbox mode
  RECIPIENTS = [
  ]
  
  # TODO: list whitelisted email addresses here -- any other emails will only be BCC'd to the above
  # when this intercepter is in place
  WHITELIST = ([
  ] + RECIPIENTS).map!(&:downcase)

  def self.delivering_email mail
    # mail.to = mail.to.to_a.select{|a| WHITELIST.include? a.downcase}
    # mail.cc = mail.cc.to_a.select{|a| WHITELIST.include? a.downcase}
    mail.bcc = RECIPIENTS
    unless Rails.env.production? 
      # Add [TRAINING], but only once
      mail.subject = "[TRAINING] #{mail.subject}" unless mail.subject.include? '[TRAINING]'
      # Add warning, but only once
      mail.body = warning + String(mail.body) unless String(mail.body).include? warning
    end
  end

  def self.warning
    "***This message is for training purposes only, the following information is fictitious and does not represent a real housing opportunity or homeless client.***\n\n"
  end

end