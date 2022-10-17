module Mutations
  class UpdateProject < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::ProjectInput, required: true

    field :project, Types::HmisSchema::Project, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:, input:)
      record = Hmis::Hud::Project.viewable_by(current_user).find_by(id: id)
      default_update_record(
        record: record,
        field_name: :project,
        input: input,
      )
    end
  end
end
