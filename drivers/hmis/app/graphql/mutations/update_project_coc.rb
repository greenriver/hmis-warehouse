module Mutations
  class UpdateProjectCoc < BaseMutation
    # includes InventoryMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::ProjectCocInput, required: true

    field :project_coc, Types::HmisSchema::ProjectCoc, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:, input:)
      record = Hmis::Hud::ProjectCoc.viewable_by(current_user).find_by(id: id)
      default_update_record(
        record: record,
        field_name: :project_coc,
        input: input,
      )
    end
  end
end
