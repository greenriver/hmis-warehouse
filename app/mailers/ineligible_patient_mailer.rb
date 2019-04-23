class IneligiblePatientMailer < DatabaseMailer
  def ineligible_patients(coordinator, patient_ids)
    @patients = patient_ids
    mail(from: ENV.fetch('HEALTH_FROM'), to: coordinator, subject: "Patients Flagged as Ineligible by MassHealth")
  end

  def no_managed_care_patients(coordinator, patient_ids)
    @patients = patient_ids
    mail(from: ENV.fetch('HEALTH_FROM'), to: coordinator, subject: "Patients Flagged without Managed Care by MassHealth")
  end
end