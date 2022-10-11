# munged out of https://gist.github.com/d11wtq/1176236
module Mail
  class DatabaseDelivery
    def initialize(parameters)
      @parameters = {}.merge(parameters)
    end

    def deliver!(mail)
      is_html, body = content_and_type(mail)
      subject = ApplicationMailer.remove_prefix(mail.subject)
      from = mail[:from]&.to_s || ENV['DEFAULT_FROM']
      Rails.logger.fatal 'no DEFAULT_FROM specified in .env; mail cannot be sent' if from.nil?
      delivery_method_options = @parameters

      # if we have a user, log the event
      User.where(email: mail[:to].addresses).each do |user|
        # store the "email" in the database
        message = ::Message.create(
          user_id: user.id,
          subject: subject,
          body: body,
          from: from,
          html: is_html,
        )
        if user.continuous_email_delivery?
          ::ImmediateMailer.immediate(message, user.email, **delivery_method_options).deliver_now
          message.update(sent_at: Time.now, seen_at: Time.now)
        end
      end

      # for anyone else, just deliver the message
      (mail[:to].addresses - User.where(email: mail[:to].addresses).pluck(:email)).each do |email|
        message = ::Message.new(
          subject: subject,
          body: body,
          from: from,
          html: is_html,
        )
        ::ImmediateMailer.immediate(message, email, **delivery_method_options).deliver_now
      end
    end

    # save content as HTML if possible
    def content_and_type(mail)
      if mail.body.parts.any?
        html_part = mail.body.parts.find { |p| p.content_type.starts_with? 'text/html' }
        return [true, html_part.body.to_s] if html_part

        text_part = mail.body.parts.find { |p| p.content_type.starts_with? 'text/plain' }
        return [false, text_part.body.to_s] if text_part
      end
      body    = mail.body.to_s
      is_html = body.strip.match?(%r{\A<html>.*</html>\z}im) # rubocop:disable Style/RegexpLiteral
      [is_html, body]
    end
  end
end
