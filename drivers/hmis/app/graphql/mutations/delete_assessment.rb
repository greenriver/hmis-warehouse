module Mutations
  class DeleteAssessment < BaseMutation
    argument :id, ID, required: true

    field :assessment, Types::HmisSchema::Assessment, null: true

    def resolve(id:)
      record = Hmis::Hud::CustomAssessment.editable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :assessment)
    end
  end
end
