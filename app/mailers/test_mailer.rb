###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

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
