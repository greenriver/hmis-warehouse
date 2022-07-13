###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class IneligiblePatientMailer < HealthMailer
  def patients_with_eligibility_problems(care_coordinator_email:, ineligible_patient_ids:, non_aco_patient_ids:)
    @ineligible_ids = ineligible_patient_ids
    @no_aco_ids = non_aco_patient_ids
    @sender = Health::Cp.sender.first
    mail(**shared_health_mailer_options, to: care_coordinator_email, subject: "Patients Flagged as Ineligible by #{@sender.receiver_name} ")
  end

  def ineligible_patients(coordinator, patient_ids)
    @patients = patient_ids
    @sender = Health::Cp.sender.first
    mail(**shared_health_mailer_options, to: coordinator, subject: "Patients Flagged as Ineligible by #{@sender.receiver_name} ")
  end

  def no_managed_care_patients(coordinator, patient_ids)
    @patients = patient_ids
    @sender = Health::Cp.sender.first
    mail(**shared_health_mailer_options, to: coordinator, subject: "Patients Flagged without Managed Care by #{@sender.receiver_name} ")
  end
end
