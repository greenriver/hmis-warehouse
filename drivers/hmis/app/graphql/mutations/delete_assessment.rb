###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteAssessment < BaseMutation
    argument :id, ID, required: true
    argument :assessment_lock_version, Integer, required: false

    field :assessment_id, ID, null: true

    def resolve(id:, assessment_lock_version: nil)
      record = Hmis::Hud::CustomAssessment.viewable_by(current_user).find_by(id: id)
      access_denied! unless record && policy_for(record, policy_type: :hmis_custom_assessment).can_delete?

      record.lock_version = assessment_lock_version if assessment_lock_version

      if record.deletion_would_cause_conflicting_enrollments?
        errors = HmisErrors::Errors.new
        errors.add :base, :invalid, full_message: 'Cannot reopen this enrollment because it would conflict with newer enrollments for this client'
        return {
          assessment_id: record.id,
          errors: errors,
        }
      end

      record.with_lock do
        is_wip = record.in_progress?

        record.destroy!

        record.form_processor.destroy_related_records!

        # Deleting the Exit Assessment "un-exits" the client by deleting the Exit record,
        # and moving the referral back to "accepted" status
        record.enrollment&.accept_referral!(current_user: current_user) if record.exit? && !is_wip

        # Deleting the Intake Assessment deletes the enrollment
        delete_household_enrollments(record: record) if record.intake?

        { assessment_id: record.id, errors: [] }
      end
    end

    def delete_household_enrollments(record:)
      return unless record.intake? && record.enrollment.present?

      # Don't delete the enrollment if it has any other intakes.
      # (This would likely be a data issue from import, since our frontend does not allow creating multiple intakes)
      return if record.enrollment.intake_assessment&.present?

      enrollments_to_delete = [record.enrollment]

      # If we're deleting the HoH enrollment, delete all household members' enrollments too.
      # This avoids leaving a dangling household without a HoH.
      if record.enrollment.head_of_household?
        record.enrollment.household_members.each do |hhm_enrollment|
          # Check if the user has permission to delete each enrollment. This deals with the hypothetical edge case:
          # If the HoH's intake is WIP, but another HHM has a completed intake,
          # the current user might not have the right permission (can_delete_enrollments) to delete all the enrollments.
          # (This would likely be a data issue from import, since our frontend disallows submitting the HHM intakes before the HoH.)
          access_denied! unless policy_for(hhm_enrollment, policy_type: :hmis_enrollment).can_delete?

          enrollments_to_delete.append(hhm_enrollment)
        end
      end

      # Destroy all the enrollments. This is done in a transaction thanks to record.with_lock above
      enrollments_to_delete.uniq.each(&:destroy!)
    end
  end
end
