###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteCeAssessment < BaseMutation
    argument :id, ID, required: true

    field :ce_assessment, Types::HmisSchema::CeAssessment, null: true

    def resolve(id:)
      record = Hmis::Hud::Assessment.viewable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :ce_assessment, permissions: [:can_edit_enrollments])
    end
  end
end
