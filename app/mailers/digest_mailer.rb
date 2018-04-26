class DigestMailer < ApplicationMailer

  def digest user, messages
    @messages = messages
    mail to: user.email, subject: "#{user.email_schedule} digest"
  end

end
