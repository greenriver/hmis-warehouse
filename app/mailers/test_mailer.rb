###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# bundle exec rails runner 'TestMailer.ping("somebody@greenriver.com").deliver_now'
# bundle exec rails runner 'TestMailer.ping("bounce@simulator.amazonses.com").deliver_now'
# bundle exec rails runner 'TestMailer.ping("complaint@simulator.amazonses.com").deliver_now'

class TestMailer < ApplicationMailer
  default from: ENV.fetch('DEFAULT_FROM')

  def ping(email)
    mail(
      to: [email],
      subject: 'test',
    ) do |format|
      format.text { render plain: "Test #{SecureRandom.hex(6)} Try this: #{clients_url}" }
    end
  end
end
