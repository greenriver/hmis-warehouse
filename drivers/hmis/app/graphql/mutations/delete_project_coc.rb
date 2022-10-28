module Mutations
  class DeleteProjectCoc < BaseMutation
    argument :id, ID, required: true

    field :project_coc, Types::HmisSchema::ProjectCoc, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:)
      record = Hmis::Hud::ProjectCoc.viewable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :project_coc)
    end
  end
end
