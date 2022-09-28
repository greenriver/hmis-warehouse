module Mutations
  class CreateOrganization < BaseMutation
    argument :input, Types::HmisSchema::OrganizationInput, required: true

    field :organization, Types::HmisSchema::Organization, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(input:)
      user = hmis_user

      organization = Hmis::Hud::Organization.new(
        **input.to_params,
        organization_id: Hmis::Hud::Organization.generate_organization_id,
        data_source_id: user.data_source_id,
        user_id: user.user_id,
        date_updated: DateTime.current,
        date_created: DateTime.current,
      )

      errors = []

      if organization.valid?
        organization.save!
      else
        errors = organization.errors
        organization = nil
      end

      {
        organization: organization,
        errors: errors,
      }
    end
  end
end
