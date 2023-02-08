module Mutations
  class CreateOrganization < BaseMutation
    argument :input, Types::HmisSchema::OrganizationInput, required: true

    field :organization, Types::HmisSchema::Organization, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(input:)
      default_create_record(
        Hmis::Hud::Organization,
        field_name: :organization,
        id_field_name: :organization_id,
        input: input,
      )
    end
  end
end
