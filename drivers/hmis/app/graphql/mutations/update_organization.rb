module Mutations
  class UpdateOrganization < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::OrganizationInput, required: true

    field :organization, Types::HmisSchema::Organization, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:, input:)
      errors = []
      organization = Hmis::Hud::Organization.viewable_by(current_user).find_by(id: id)

      if organization.present?
        organization.update(**input.to_params)
        errors += organization.errors.errors unless organization.valid?
      else
        errors << InputValidationError.new("No organization found with ID '#{id}'", attribute: 'id') unless organization.present?
      end

      {
        organization: organization,
        errors: errors,
      }
    end
  end
end
