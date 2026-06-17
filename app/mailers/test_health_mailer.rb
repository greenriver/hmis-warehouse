###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# bundle exec rails runner 'TestHealthMailer.ping("somebody@greenriver.com").deliver_now'

class TestHealthMailer < HealthMailer
  def ping(email)
    mail(
      **shared_health_mailer_options,
      to: [email],
      subject: 'test',
    ) do |format|
      format.text { render plain: "Test #{SecureRandom.hex(6)}" }
    end
  end
end
