module Mutations
  class DeleteAssessment < BaseMutation
    argument :id, ID, required: true

    field :assessment, Types::HmisSchema::Assessment, null: true

    def resolve(id:)
      record = Hmis::Hud::Assessment.viewable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :assessment, permissions: [:can_edit_enrollments])
    end
  end
end
