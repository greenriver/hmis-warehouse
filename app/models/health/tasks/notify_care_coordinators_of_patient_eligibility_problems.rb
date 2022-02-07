###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::Tasks
  class NotifyCareCoordinatorsOfPatientEligibilityProblems
    def notify!
      care_coordinator_ids = patient_scope.
        program_ineligible.
        distinct.
        pluck(:care_coordinator_id)

      User.active.where(id: care_coordinator_ids).each do |user|
        ineligible_patients = patient_scope.
          no_coverage.
          where(care_coordinator_id: user.id).
          pluck(:id, :client_id).to_h

        no_aco_patients = patient_scope.
          standard_coverage.
          where(care_coordinator_id: user.id).
          pluck(:id, :client_id).to_h

        IneligiblePatientMailer.patients_with_eligibility_problems(care_coordinator_email: user.email,
          ineligible_patient_ids: ineligible_patients.values,
          non_aco_patient_ids: no_aco_patients.values).deliver_now

        Health::Patient.find(ineligible_patients.keys + no_aco_patients.keys).each do |patient|
          patient.update!(eligibility_notification: Time.now)
        end
      end
    end

    def patient_scope
      Health::Patient.
        participating.
        with_unsent_eligibility_notification
    end
  end
end
