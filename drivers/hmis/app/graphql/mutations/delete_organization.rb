module Mutations
  class DeleteOrganization < BaseMutation
    argument :id, ID, required: true

    field :organization, Types::HmisSchema::Organization, null: true

    def resolve(id:)
      record = Hmis::Hud::Organization.editable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :organization)
    end
  end
end
