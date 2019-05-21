module Health::Tasks
  class NotifyCareCoordinatorsOfPatientEligibilityProblems
    def notify!
      care_coordinator_ids = patient_scope.
        program_ineligible.
        distinct.
        pluck(:care_coordinator_id)

      User.where(id: care_coordinator_ids).each do |user|
        ineligible_patients = patient_scope.
          no_coverage.
          where(care_coordinator_id: user.id).
          pluck(:id, :client_id)

        no_aco_patients = patient_scope.
          standard_coverage.
          where(care_coordinator_id: user.id).
          pluck(:id, :client_id)

        IneligiblePatientMailer.patients_with_eligibility_problems(user.email, client_ids(ineligible_patients), client_ids(no_aco_patients)).deliver_now

        Health::Patient.find(patient_ids(ineligible_patients) + patient_ids(no_aco_patients)).each do |patient|
          patient.update!(eligibility_notification: Time.now)
        end
      end
    end

    def patient_ids(list)
      list.map{|entry| entry.first}
    end

    def client_ids(list)
      list.map{|entry| entry.last}
    end

    def patient_scope
      Health::Patient.
        participating.
        with_unsent_eligibility_notification
    end
  end
end