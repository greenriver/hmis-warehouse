###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteAssessment < BaseMutation
    argument :id, ID, required: true
    argument :assessment_lock_version, Integer, required: false

    field :assessment_id, ID, null: true

    def resolve(id:, assessment_lock_version: nil)
      record = Hmis::Hud::CustomAssessment.viewable_by(current_user).find_by(id: id)
      raise HmisErrors::ApiError, 'Record not found' unless record.present?

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

        result = default_delete_record(
          record: record,
          field_name: :assessment,
          authorize: ->(assessment, user) do
            # WIP assessments, including WIP Intakes, can be deleted by users that have "can_edit_enrollments"
            return user.can_edit_enrollments_for?(assessment.enrollment) if is_wip

            if record.intake?
              user.can_delete_enrollments_for?(assessment.enrollment)
            else
              user.can_delete_assessments_for?(assessment.enrollment)
            end
          end,
          after_delete: -> do
            record.form_processor.destroy_dependents!

            # Deleting the Exit Assessment "un-exits" the client by deleting the Exit record,
            # and moving the referral back to "accepted" status
            record.enrollment&.accept_referral!(current_user: current_user) if record.exit? && !is_wip

            # Deleting the Intake Assessment deletes the enrollment
            record.enrollment&.destroy! if record.intake? && !record.enrollment&.intake_assessment&.present?
          end,
        )

        { assessment_id: result[:assessment]&.id, errors: result[:errors] }
      end
    end
  end
end
