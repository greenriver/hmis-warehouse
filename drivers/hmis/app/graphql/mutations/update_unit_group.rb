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

      # If name is being changed, check that it's still unique in the project.
      # (This is also validated on the model, but we want to return a more user-friendly error message)
      if input.name.present? && input.name != unit_group.name
        # rubocop:disable Style/IfUnlessModifier
        if Hmis::UnitGroup.where(project_id: unit_group.project_id, name: input.name).exists?
          errors.add :name, :invalid, message: 'must be unique in the project'
        end
        # rubocop:enable Style/IfUnlessModifier
      end

      # Prevent changing or clearing workflow template if one is already set
      # rubocop:disable Style/IfUnlessModifier
      if unit_group.workflow_template_identifier.present? && input.workflow_template_identifier != unit_group.workflow_template_identifier
        errors.add :workflow_template_identifier, :invalid, message: 'cannot be changed once set'
      end
      # rubocop:enable Style/IfUnlessModifier

      # Prevent changing or clearing CE event type if one is already set
      # rubocop:disable Style/IfUnlessModifier
      if unit_group.ce_event_type.present? && input.ce_event_type != unit_group.ce_event_type
        errors.add :ce_event_type, :invalid, message: 'cannot be changed once set'
      end
      # rubocop:enable Style/IfUnlessModifier

      return { errors: errors.errors } if errors.any?

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
