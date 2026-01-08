###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteInventory < BaseMutation
    argument :id, ID, required: true

    field :inventory, Types::HmisSchema::Inventory, null: true

    def resolve(id:)
      record = Hmis::Hud::Inventory.viewable_by(current_user).find_by(id: id)
      access_denied! unless record && policy_for(record.project, policy_type: :hmis_project).can_edit?

      record.destroy!
      {
        inventory: record,
      }
    end
  end
end
