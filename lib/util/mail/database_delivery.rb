# munged out of https://gist.github.com/d11wtq/1176236
module Mail
  class DatabaseDelivery

    def initialize(parameters)
      @parameters = parameters
    end

    def deliver!(mail)
      User.where( email: mail[:to].addresses ).each do |user|
        # store the "email" in the database
        message = ::Message.create(
          user_id: user.id,
          subject: mail.subject,
          body:    mail.body.to_s,
          from:    mail[:from].addresses.first,
          html:    /\A<html>.*<\/html>\z/im === mail.body.to_s.strip,
        )
        if user.continuous_email_delivery?
          # use the configured delivery method
          delivery_method = Rails.configuration.action_mailer.delivery_method
          options = case delivery_method
          when :letter_opener
            { location: Rails.root.join( 'tmp', 'letter_opener' ) } # for some reason it isn't getting the default
          else
            {}
          end
          delivery_method = ActionMailer::Base.delivery_methods[delivery_method]
          copy = mail.dup
          copy.to = user.email
          copy.delivery_method delivery_method, options
          copy.perform_deliveries = true
          copy.deliver
          message.update_attributes sent_at: DateTime.current, seen_at: DateTime.current
        end
      end
    end
  end
end