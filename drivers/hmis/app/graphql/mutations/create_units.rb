###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class CreateUnits < BaseMutation
    argument :input, Types::HmisSchema::UnitInput, required: true

    field :units, [Types::HmisSchema::Unit], null: true

    def resolve(input:)
      unit_group = Hmis::UnitGroup.find(input.unit_group_id)
      unit_type = unit_group.unit_type
      project = unit_group.project
      raise 'Access denied' unless current_user.permissions_for?(project, :can_manage_units)

      errors = HmisErrors::Errors.new
      errors.add :count, :required unless input.count.present?
      errors.add :count, :out_of_range, message: 'must be positive' if input.count&.negative?
      errors.add :count, :out_of_range, message: 'must be non-zero' if input.count&.zero?
      errors.add :count, :out_of_range, message: 'must not be greater than 200' if input.count && input.count > 200
      return { errors: errors.errors } if errors.any?

      # Create Units
      units = (1..input.count).map do
        Hmis::Unit.new(
          hmis_unit_group_id: unit_group.id,
          user_id: current_user.id,
          # TODO(#7814) - remove
          project: project,
          unit_type: unit_type,
        )
      end

      Hmis::Unit.transaction do
        units.each(&:save!)
        unit_type.track_availability(project_id: project.id, user_id: current_user.id)
      end

      {
        units: units,
        errors: [],
      }
    end
  end
end
