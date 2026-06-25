###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteOrganization < BaseMutation
    argument :id, ID, required: true

    field :organization, Types::HmisSchema::Organization, null: true

    def resolve(id:)
      record = Hmis::Hud::Organization.viewable_by(current_user).find_by(id: id)
      access_denied! unless record && policy_for(record, policy_type: :hmis_organization).can_delete?

      record.destroy!
      {
        organization: record,
        errors: [],
      }
    end
  end
end
