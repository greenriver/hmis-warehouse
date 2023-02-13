module Mutations
  class UpdateProjectCoc < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::ProjectCocInput, required: true

    field :project_coc, Types::HmisSchema::ProjectCoc, null: true

    def resolve(id:, input:)
      record = Hmis::Hud::ProjectCoc.editable_by(current_user).find_by(id: id)
      default_update_record(
        record: record,
        field_name: :project_coc,
        input: input,
      )
    end
  end
end
