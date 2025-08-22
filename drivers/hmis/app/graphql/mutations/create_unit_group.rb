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
      errors = HmisErrors::Errors.new

      # Explicitly add errors if required fields are missing. (They are not required on the UnitGroupInput type, since that is also used for update)
      errors.add :project_id, :required unless input.project_id.present?
      errors.add :name, :required unless input.name.present?
      return { errors: errors.errors } if errors.any?

      project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: input.project_id)

      access_denied! unless project.present?
      access_denied! unless current_user.permissions_for?(project, :can_manage_units)

      # unit_type = Hmis::UnitType.find_by(id: input.unit_type_id)
      # raise 'Invalid unit type' if input.unit_type_id.present? && !unit_type.present?

      # errors.add :count, :required unless input.count.present?
      # errors.add :count, :out_of_range, message: 'must be positive' if input.count&.negative?
      # errors.add :count, :out_of_range, message: 'must be non-zero' if input.count&.zero?
      errors.add :name, :invalid, message: 'must be unique in the project' if Hmis::UnitGroup.exists?(project_id: project.id, name: input.name)
      return { errors: errors.errors } if errors.any?

      unit_group = Hmis::UnitGroup.create!(
        project_id: project.id,
        workflow_template_identifier: input.workflow_template_identifier,
        name: input.name,
        ce_event_type: input.ce_event_type,
      )

      {
        unit_group: unit_group,
        errors: [],
      }
    end
  end
end
