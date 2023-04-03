###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteOrganization < BaseMutation
    argument :id, ID, required: true

    field :organization, Types::HmisSchema::Organization, null: true

    def resolve(id:)
      record = Hmis::Hud::Organization.viewable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :organization, permissions: [:can_delete_organization])
    end
  end
end
