module Mutations
  class DeleteProject < BaseMutation
    argument :id, ID, required: true

    field :project, Types::HmisSchema::Project, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:)
      record = Hmis::Hud::Project.editable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :project)
    end
  end
end
