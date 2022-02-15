###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class FlagIneligiblePatientsJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(inquiry_id)
      inquiry = Health::EligibilityInquiry.find(inquiry_id)
      response = inquiry.eligibility_response

      return unless response

      Health::Patient.transaction do
        patient_aco_changes = {}

        # Update the last check date, and since we got a response, we know the id is valid
        patient_scope(response.subscriber_ids).find_each do |patient|
          patient.update!(coverage_inquiry_date: inquiry.service_date,
                          invalid_id: false)
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
        patient_scope(response.managed_care_ids - response.ineligible_ids).find_each do |patient|
          aco = response.aco_names[patient.medicaid_id]

          previous_aco = patient.aco_name if patient.aco_name.present? && patient.aco_name != aco
          patient.update!(coverage_level: Health::Patient.coverage_level_managed_value,
                          previous_aco_name: previous_aco,
                          aco_name: aco)

          if aco.present?
            aco_id = Health::AccountableCareOrganization.active.find_by(edi_name: aco)&.id
            patient.patient_referral.update!(accountable_care_organization_id: aco_id) if aco_id.present?

            if previous_aco.present?
              patient_aco_changes[patient.id] = {
                previous_aco: previous_aco,
                updated: aco_id.present?,
              }
            end
          end
        end

        response.update(patient_aco_changes: patient_aco_changes)

        # Mark ineligible patients
        patient_scope(response.ineligible_ids).find_each do |patient|
          patient.update!(coverage_level: Health::Patient.coverage_level_none_value,
                          aco_name: nil)
        end

        # Mark patients with invalid ids
        patient_scope(response.invalid_subscriber_ids).find_each do |patient|
          patient.update!(invalid_id: true)
        end
      end
    end

    def patient_scope(ids)
      Health::Patient.where(medicaid_id: ids).
        preload(:patient_referral)
    end
  end
end
