module Mutations
  class UpdateOrganization < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::OrganizationInput, required: true

    field :organization, Types::HmisSchema::Organization, null: true

    def resolve(id:, input:)
      record = Hmis::Hud::Organization.viewable_by(current_user).find_by(id: id)
      default_update_record(
        record: record,
        field_name: :organization,
        input: input,
        permissions: [:can_edit_organization],
      )
    end
  end
end
