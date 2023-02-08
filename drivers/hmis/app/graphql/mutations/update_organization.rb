module Mutations
  class UpdateOrganization < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::OrganizationInput, required: true

    field :organization, Types::HmisSchema::Organization, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:, input:)
      record = Hmis::Hud::Organization.editable_by(current_user).find_by(id: id)
      default_update_record(
        record: record,
        field_name: :organization,
        input: input,
      )
    end
  end
end
