class ImmediateMailer < ApplicationMailer

  def immediate message, to
    @message = message
    mail from: message.from, to: to, subject: "#{prefix} #{@message.subject}"
  end

end
