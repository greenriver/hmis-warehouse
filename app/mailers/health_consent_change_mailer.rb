###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HealthConsentChangeMailer < DatabaseMailer
  def consent_changed(new_patients:, consented:, revoked_consent:, unmatched:, user:)
    @consented = consented
    @revoked_consent = revoked_consent
    @new_patients = new_patients
    @unmatched = unmatched
    return unless user.active?

    mail(from: ENV.fetch('HEALTH_FROM'), to: user.email, subject: 'Health Data Import Summary')
  end
end
