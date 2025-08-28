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
      errors.add :unit_type_id, :required unless input.unit_type_id.present?
      return { errors: errors.errors } if errors.any?

      # Validate unit_type exists
      unit_type = Hmis::UnitType.find_by(id: input.unit_type_id)
      errors.add :unit_type_id, :invalid unless unit_type.present?
      return { errors: errors.errors } if errors.any?

      unit_group = Hmis::UnitGroup.new(
        project_id: project.id,
        workflow_template_identifier: input.workflow_template_identifier,
        name: input.name,
        ce_event_type: input.ce_event_type,
        unit_type: unit_type,
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
