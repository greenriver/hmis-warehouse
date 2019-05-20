module Health::Tasks
  class NotifyCareCoordinatorsOfPatientEligibilityProblems
    def notify!
      care_coordinator_ids = patient_scope.
        program_ineligible.
        distinct.
        pluck(:care_coordinator_id)

      User.where(id: care_coordinator_ids).each do |user|
        ineligible_patient_ids = patient_scope.
          no_coverage.
          where(care_coordinator_id: user.id).
          pluck(:client_id)

        no_aco_patient_ids = patient_scope.
          standard_coverage.
          where(care_coordinator_id: user.id).
          pluck(:client_id)

        IneligiblePatientMailer.patients_with_eligibility_problems(user.email, ineligible_patient_ids, no_aco_patient_ids).deliver_now

        Health::Patient.find(ineligible_patient_ids + no_aco_patient_ids).each do |patient|
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