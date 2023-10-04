###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteCustomCaseNote < CleanBaseMutation
    argument :id, ID, required: true

    field :custom_case_note, Types::HmisSchema::CustomCaseNote, null: true

    def resolve(id:)
      record = Hmis::Hud::CustomCaseNote.viewable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :custom_case_note, permissions: [:can_edit_enrollments])
    end
  end
end
