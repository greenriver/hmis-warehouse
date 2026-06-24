###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteAssessment < BaseMutation
    include DeletesHouseholdEnrollments

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

        enrollment = record.enrollment

        # Deleting the Exit Assessment "un-exits" the client by deleting the Exit record,
        # and moving the referral back to "accepted" status
        enrollment.accept_referral!(current_user: current_user) if record.exit? && !is_wip

        # Deleting the Intake deletes the enrollment.
        # Don't delete the enrollment if it has any other intakes besides this one. (Not allowed in HMIS, likely a data issue from import)
        if record.intake? && !enrollment.intake_assessment.present?
          # If this is the HoH, delete all household enrollments to avoid leaving behind a household with no HoH
          if enrollment.head_of_household?
            destroy_household!(hoh_enrollment: enrollment)
          else
            enrollment.destroy!
          end
        end

        { assessment_id: record.id, errors: [] }
      end
    end
  end
end
