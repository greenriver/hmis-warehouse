module Mutations
  class DeleteOrganization < BaseMutation
    argument :id, ID, required: true

    field :organization, Types::HmisSchema::Organization, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:)
      record = Hmis::Hud::Organization.editable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :organization)
    end
  end
end
