class ImmediateMailer < ApplicationMailer

  def immediate message, to
    @message = message
    mail to: to, subject: @message.subject
  end

end
