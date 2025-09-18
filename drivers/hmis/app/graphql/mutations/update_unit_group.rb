###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class UpdateUnitGroup < CleanBaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::UnitGroupInput, required: true

    field :unit_group, Types::HmisSchema::UnitGroup, null: true

    def resolve(id:, input:)
      unit_group = Hmis::UnitGroup.viewable_by(current_user).find_by(id: id)

      access_denied! unless unit_group.present?
      access_denied! unless current_user.permissions_for?(unit_group.project, :can_manage_units)

      errors = HmisErrors::Errors.new

      unit_group.assign_attributes(
        name: input.name,
        workflow_template_identifier: input.workflow_template_identifier,
        ce_event_type: input.ce_event_type,
      )

      if unit_group.valid?
        unit_group.save!
      else
        errors.add_ar_errors(unit_group.errors&.errors)
        unit_group = nil
      end

      {
        unit_group: unit_group,
        errors: errors.errors,
      }
    end
  end
end
