###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# bundle exec rails runner 'TestDatabaseMailer.ping("somebody@greenriver.com").deliver_now'

class TestDatabaseMailer < DatabaseMailer
  default from: 'noreply@greenriver.com'

  def ping(email)
    mail(
      to: [email],
      subject: 'test',
    ) do |format|
      format.text { render plain: "Test #{SecureRandom.hex(6)}" }
    end
  end
end
