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
      project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: input.project_id)

      raise 'Not found' unless project.present?
      raise 'Access denied' if project.present? && !current_user.permissions_for?(project, :can_manage_units)

      errors = HmisErrors::Errors.new
      errors.add :count, :required unless input.count.present?
      errors.add :count, :out_of_range, message: 'must be positive' if input.count&.negative?
      errors.add :count, :out_of_range, message: 'must be non-zero' if input.count&.zero?
      errors.add :count, :out_of_range, message: 'must not be greater than 200' if input.count && input.count > 200
      return { errors: errors.errors } if errors.any?

      unit_group = project.unit_groups.find_by(id: input.unit_group_id)
      errors.add :unit_group_id, :required unless unit_group.present?
      return { errors: errors.errors } if errors.any?

      unit_type = unit_group.unit_type
      raise "Cannot add units to unit group #{unit_group.id}. Missing unit type" unless unit_type.present?

      # Create Units
      common = { user_id: current_user.id, created_at: Time.now, updated_at: Time.now }
      units = (1..input.count).map do
        Hmis::Unit.new(
          project_id: project.id,
          unit_type_id: unit_type&.id,
          hmis_unit_group_id: unit_group&.id,
          **common,
        )
      end

      units.filter(&:invalid?).each do |unit|
        errors.add_ar_errors(unit.errors&.errors)
      end
      errors.deduplicate!
      return { errors: errors.errors } if errors.any?

      units.each(&:save!)

      {
        units: units,
        errors: [],
      }
    end
  end
end
