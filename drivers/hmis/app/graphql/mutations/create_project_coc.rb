module Mutations
  class CreateProjectCoc < BaseMutation
    argument :input, Types::HmisSchema::ProjectCocInput, required: true

    field :project_coc, Types::HmisSchema::ProjectCoc, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(input:)
      default_create_record(
        Hmis::Hud::ProjectCoc,
        field_name: :project_coc,
        id_field_name: :project_coc_id,
        input: input,
      )
    end
  end
end
