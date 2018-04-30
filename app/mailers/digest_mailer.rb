class DigestMailer < ApplicationMailer

  def digest user, messages
    @messages = messages
    mail to: user.email, subject: "#{prefix} #{user.email_schedule} digest"
  end

end
