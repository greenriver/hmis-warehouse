###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class CreateUnitGroup < CleanBaseMutation
    argument :input, Types::HmisSchema::UnitGroupInput, required: true

    field :unit_group, Types::HmisSchema::UnitGroup, null: true

    def resolve(input:)
      project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: input.project_id)

      access_denied! unless project.present?
      access_denied! unless current_user.permissions_for?(project, :can_manage_units)

      errors = HmisErrors::Errors.new

      # TODO(#8157) - accept Unit Type. Constrain to project.possible_unit_types
      # unit_type = project.possible_unit_types.find_by(id: input.unit_type_id)
      # raise 'Invalid unit type' if input.unit_type_id.present? && !unit_type.present?

      # errors.add :count, :required unless input.count.present?
      # errors.add :count, :out_of_range, message: 'must be positive' if input.count&.negative?
      # errors.add :count, :out_of_range, message: 'must be non-zero' if input.count&.zero?
      # return { errors: errors.errors } if errors.any?

      unit_group = Hmis::UnitGroup.new(
        project_id: project.id,
        workflow_template_identifier: input.workflow_template_identifier,
        name: input.name,
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
        errors: errors,
      }
    end
  end
end
