module Mutations
  class CreateProject < BaseMutation
    argument :input, Types::HmisSchema::ProjectInput, required: true

    field :project, Types::HmisSchema::Project, null: true

    def resolve(input:)
      default_create_record(
        Hmis::Hud::Project,
        field_name: :project,
        id_field_name: :project_id,
        input: input,
        permissions: [:can_edit_project_details],
      )
    end
  end
end
