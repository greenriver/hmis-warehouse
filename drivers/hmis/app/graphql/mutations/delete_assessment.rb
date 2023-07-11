###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteAssessment < BaseMutation
    argument :id, ID, required: true

    field :assessment_id, ID, null: true

    def resolve(id:)
      record = Hmis::Hud::CustomAssessment.viewable_by(current_user).find_by(id: id)
      raise HmisErrors::ApiError, 'Record not found' unless record.present?

      # FIXME(#185552893): this mutation should delete all the related records linked to the FormProcessor
      record.transaction do
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
            # Deleting the Exit Assessment "un-exits" the client by deleting the Exit record,
            # and moving the referral back to "accepted" status
            if record.exit? && !is_wip
              record.enrollment&.exit&.destroy # FIXME(#185552893) this becomes redundant
              record.enrollment&.accept_referral!(current_user: current_user)
            end

            # Deleting the Intake Assessment deletes the enrollment
            record.enrollment&.destroy if record.intake?
          end,
        )

        { assessment_id: result[:assessment]&.id, errors: result[:errors] }
      end
    end
  end
end
