class ImmediateMailer < ApplicationMailer

  def immediate message, to
    @message = message
    mail to: to, subject: "#{prefix} #{@message.subject}"
  end

end
