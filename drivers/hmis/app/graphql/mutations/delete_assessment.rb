###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteAssessment < BaseMutation
    argument :id, ID, required: true

    field :assessment, Types::HmisSchema::Assessment, null: true

    def resolve(id:)
      record = Hmis::Hud::CustomAssessment.viewable_by(current_user).find_by(id: id)

      record.transaction do
        role = record.custom_form.definition.role
        default_delete_record(
          record: record,
          field_name: :assessment,
          authorize: ->(assessment, user) do
            return false if !assessment.in_progress? && assessment.custom_form.definition.role == 'INTAKE'
            return true if assessment.in_progress? && user.can_edit_enrollments_for?(assessment.client)
            return true if !assessment.in_progress? && user.can_delete_assessments_for?(assessment.client)

            false
          end,
          after_delete: -> do
            record.enrollment&.exit&.destroy if role == 'EXIT'
          end,
        )
      end
    end
  end
end
