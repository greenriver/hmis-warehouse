# bundle exec rails runner 'TestMailer.ping("somebody@greenriver.com").deliver_now'

class TestMailer < ActionMailer::Base
  default from: ENV.fetch('DEFAULT_FROM')

  def ping(email)
    mail({
      to: [email],
      subject: 'test'
    }) do |format|
      format.text { render plain: "Test #{SecureRandom.hex(6)}" }
    end
  end
end
