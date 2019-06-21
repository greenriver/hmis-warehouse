###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

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
          patient_scope(response.eligible_ids - response.managed_care_ids).find_each do |patient|
            patient.update!(coverage_level: Health::Patient.coverage_level_standard_value,
              aco_name: nil)
          end

          # Set the eligibility level for managed care patients
          patient_scope(response.managed_care_ids).find_each do |patient|
            aco = response.aco_names[patient.medicaid_id]
            if patient.aco_name.present? && patient.aco_name != aco
              previous_aco = patient.aco_name
            end
            patient.update!(coverage_level: Health::Patient.coverage_level_managed_value,
              previous_aco_name: previous_aco,
              aco_name: aco)
          end

          # Mark ineligible patients
          patient_scope(response.ineligible_ids).find_each do |patient|
            patient.update!(coverage_level: Health::Patient.coverage_level_none_value,
              aco_name: nil)
          end
        end
      end
    end

    def patient_scope(ids)
      Health::Patient.where(medicaid_id: ids)
    end
  end
end