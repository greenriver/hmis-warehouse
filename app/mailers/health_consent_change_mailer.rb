class HealthConsentChangeMailer < DatabaseMailer

  def consent_changed new_patients:, consented:, revoked_consent:, unmatched:, user:
    @consented = consented
    @revoked_consent = revoked_consent
    @new_patients = new_patients
    @unmatched = unmatched
    mail(from: '"Boston Coordinated Care Hub" <cas-help@boston.gov>', to: user.email, subject: "Health Data Import Summary")
  end
end