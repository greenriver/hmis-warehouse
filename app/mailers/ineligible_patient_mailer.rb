class IneligiblePatientMailer < DatabaseMailer
  def ineligible_patients(coordinator, patient_ids)
    @patients = patient_ids
    @sender = Health::Cp.sender.first
    mail(from: ENV.fetch('HEALTH_FROM'), to: coordinator, subject: "Patients Flagged as Ineligible by #{@sender.receiver_name} ")
  end

  def no_managed_care_patients(coordinator, patient_ids)
    @patients = patient_ids
    @sender = Health::Cp.sender.first
    mail(from: ENV.fetch('HEALTH_FROM'), to: coordinator, subject: "Patients Flagged without Managed Care by #{@sender.receiver_name} ")
  end
end