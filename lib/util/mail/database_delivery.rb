# munged out of https://gist.github.com/d11wtq/1176236
module Mail
  class DatabaseDelivery

    def initialize(parameters)
      @parameters = parameters
    end

    def deliver!(mail)
      is_html, body = content_and_type mail
      subject       = ApplicationMailer.remove_prefix mail.subject
      from          = mail[:from].addresses.first
      User.where( email: mail[:to].addresses ).each do |user|
        # store the "email" in the database
        message = ::Message.create(
          user_id: user.id,
          subject: subject,
          body:    body,
          from:    from,
          html:    is_html,
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

    # save content as HTML if possible
    def content_and_type(mail)
      if mail.body.parts.any?
        html_part = mail.body.parts.find{ |p| p.content_type.starts_with? "text/html" }
        return [ true, html_part.body.to_s ] if html_part
        text_part = mail.body.parts.find{ |p| p.content_type.starts_with? "text/plain" }
        return [ false, text_part.body.to_s ] if text_part
      end
      body    = mail.body.to_s
      is_html = /\A<html>.*<\/html>\z/im === body.strip
      [ is_html, body ]
    end
  end
end