class IneligiblePatientMailer < DatabaseMailer
  def patients_with_eligibility_problems(coordinator, ineligible_ids, no_aco_ids)
    @ineligible_ids = ineligible_ids
    @no_aco_ids = no_aco_ids
    @sender = Health::Cp.sender.first
    mail(from: ENV.fetch('HEALTH_FROM'), to: coordinator, subject: "Patients Flagged as Ineligible by #{@sender.receiver_name} ")
  end

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