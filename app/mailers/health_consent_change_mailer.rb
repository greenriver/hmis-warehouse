class HealthConsentChangeMailer < ApplicationMailer

  def consent_changed new_patients:, consented:, revoked_consent:, user:
    @consented = consented
    @revoked_consent = revoked_consent
    @new_patients = new_patients
    mail(to: user.email, subject: "[Warehouse] Health Data Import Summary")
  end
end