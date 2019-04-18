module Health
  class FlagIneligiblePatientsJob < ActiveJob::Base
    def perform
      # We only care about the most recent response
      inquiry = Health::EligibilityInquiry.last
      response = inquiry.eligibility_response

      if response
        # Clear any ineligiblity flags for patients in the response
        Health::Patient.where(medicaid_id: response.eligible_ids).update_all(ineligible: nil)

        # Mark ineligible patients
        Health::Patient.where(medicaid_id: response.ineligible_ids).update_all(ineligible: inquiry.service_date)

        notify_care_coordinators(response.ineligible_ids)
      end
    end

    def notify_care_coordinators(ineligible_ids)
      groups = Health::Patient.where(medicaid_id: ineligible_ids).
        where.not(care_coordinator_id: nil).
        group_by{|patient| patient.care_coordinator}

      groups.each do |coordinator, patients|
        IneligiblePatientMailer.ineligible_patients(coordinator, patients).deliver_later
      end
    end
  end
end