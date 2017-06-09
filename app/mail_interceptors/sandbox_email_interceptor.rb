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
    if Rails.env.staging?
      mail.subject = "[TRAINING] #{mail.subject}"
      mail.body = warning + String(mail.body)
    end
  end

  def self.warning
    "***This message is for training purposes only, the following information is fictitious and does not represent a real housing opportunity or homeless client.***\n\n"
  end

end