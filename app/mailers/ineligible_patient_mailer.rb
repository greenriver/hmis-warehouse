class IneligiblePatientMailer < DatabaseMailer
  def ineligible_patients(coordinator, patients)
    @patients = patients
    mail(from: '"Boston Coordinated Care Hub" <cas-help@boston.gov>', to: coordinator.email, subject: "Patients Flagged as Ineligible by MassHealth")
  end
end