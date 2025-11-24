###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteUnitGroup < CleanBaseMutation
    argument :id, ID, required: true

    field :unit_group, Types::HmisSchema::UnitGroup, null: true

    def resolve(id:)
      unit_group = Hmis::UnitGroup.viewable_by(current_user).find_by(id: id)

      access_denied! unless unit_group.present?
      access_denied! unless current_user.permissions_for?(unit_group.project, :can_manage_units)

      errors = HmisErrors::Errors.new

      # Validate that there are no units in the group
      if unit_group.units.count > 0
        errors.add(:base, :invalid, full_message: 'Cannot delete unit group with units')
        return { unit_group: nil, errors: errors }
      end

      # Soft-delete the unit group
      unit_group.destroy!

      {
        unit_group: unit_group,
        errors: errors,
      }
    end
  end
end
