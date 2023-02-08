module Mutations
  class DeleteProjectCoc < BaseMutation
    argument :id, ID, required: true

    field :project_coc, Types::HmisSchema::ProjectCoc, null: true

    def resolve(id:)
      record = Hmis::Hud::ProjectCoc.editable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :project_coc)
    end
  end
end
