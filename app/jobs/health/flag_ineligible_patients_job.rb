module Health
  class FlagIneligiblePatientsJob < ActiveJob::Base
    def perform
      # We only care about the most recent response
      inquiry = Health::EligibilityInquiry.last
      response = inquiry.eligibility_response

      if response
        # Update the last check date
        Health::Patient.where(medicaid_id: response.subscriber_ids).update_all(coverage_inquiry_date: inquiry.service_date)

        # Set the eligibility level for covered patients
        Health::Patient.where(medicaid_id: response.eligible_ids).update_all(coverage_level: 'standard')

        # Set the eligibility level for managed care patients
        Health::Patient.where(medicaid_id: response.managed_care_ids).update_all(coverage_level: 'managed')

        # Mark ineligible patients
        Health::Patient.where(medicaid_id: response.ineligible_ids).update_all(coverage_level: 'none')

        notify_care_coordinators(response)
      end
    end

    def notify_care_coordinators(response)
      groups = Health::Patient.where(medicaid_id: response.ineligible_ids).
        where.not(care_coordinator_id: nil).
        group_by{|patient| patient.care_coordinator}

      groups.each do |coordinator, patients|
        IneligiblePatientMailer.ineligible_patients(coordinator, patients).deliver_later
      end

      groups = Health::Patient.where(medicaid_id: response.eligible_ids - response.managed_care_ids).
          where.not(care_coordinator_id: nil).
          group_by{|patient| patient.care_coordinator}

      groups.each do |coordinator, patients|
        IneligiblePatientMailer.no_managed_care_patients(coordinator, patients).deliver_later
      end
    end
  end
end