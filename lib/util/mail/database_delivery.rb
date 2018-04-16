# munged out of https://gist.github.com/d11wtq/1176236
module Mail
  class DatabaseDelivery

    def initialize(parameters)
      # maybe we'll need something here
    end

    def deliver!(mail)
      # store the "email" in the database
      message = Notification.create(
        subject: mail.subject,
        body:    mail.body,
        to:      mail[:to].addresses,
        from:    mail[:from].addresses,
      )
      
      # perhaps do websocket notification here at some point
      # MailChannel.notify message
    end
  end
end