module Health
  class FlagIneligiblePatientsJob < ActiveJob::Base
    def perform(inquiry_id)
      inquiry = Health::EligibilityInquiry.find(inquiry_id)
      response = inquiry.eligibility_response

      if response
        Health::Patient.transaction do
          # Update the last check date
          patient_scope(response.subscriber_ids).find_each do |patient|
            patient.update!(coverage_inquiry_date: inquiry.service_date)
          end

          # Clear the eligibility notification flag on managed patients, so that if they lose eligibility again,
          # we will re-flag them
          patient_scope(response.managed_care_ids).find_each do |patient|
            patient.update!(eligibility_notification: nil)
          end

          # Set the eligibility level for covered patients
          patient_scope(response.eligible_ids).find_each do |patient|
            patient.update!(coverage_level: Health::Patient.coverage_level_standard_value)
          end

          # Set the eligibility level for managed care patients
          patient_scope(response.managed_care_ids).find_each do |patient|
            patient.update!(coverage_level: Health::Patient.coverage_level_managed_value)
          end

          # Mark ineligible patients
          patient_scope(response.ineligible_ids).find_each do |patient|
            patient.update!(coverage_level: Health::Patient.coverage_level_none_value)
          end
        end
      end
    end

    def patient_scope(ids)
      Health::Patient.where(medicaid_id: ids)
    end
  end
end