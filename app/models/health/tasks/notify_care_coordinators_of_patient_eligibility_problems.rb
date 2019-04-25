module Health::Tasks
  class NotifyCareCoordinatorsOfPatientEligibilityProblems
    def notify!
      care_coordinator_ids = Health::Patient.
        should_be_notified.
        program_ineligible.
        distinct.
        pluck(:care_coordinator_id)

      User.where(id: care_coordinator_ids).each do |user|
        ineligible_patient_ids = Health::Patient.
          should_be_notified.
          no_coverage.
          where(care_coordinator_id: user.id).
          pluck(:id)

        no_aco_patient_ids = Health::Patient.
          should_be_notified.
          standard_coverage.
          where(care_coordinator_id: user.id).
          pluck(:id)

        IneligiblePatientMailer.patients_with_eligibility_problems(user.email, ineligible_patient_ids, no_aco_patient_ids).deliver_now

        Health::Patient.find(ineligible_patient_ids + no_aco_patient_ids).each do |patient|
          patient.update!(eligibility_notification: Time.now)
        end
      end
    end
  end
end