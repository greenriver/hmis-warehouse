###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CreateUnits < BaseMutation
    argument :input, Types::HmisSchema::UnitInput, required: true

    field :units, [Types::HmisSchema::Unit], null: true

    def resolve(input:)
      project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: input.project_id)

      raise 'Not found' unless project.present?
      raise 'Access denied' if project.present? && !current_user.permissions_for?(project, :can_manage_units)

      unit_type = Hmis::UnitType.find_by(id: input.unit_type_id)
      raise 'Invalid unit type' if input.unit_type_id.present? && !unit_type.present?

      errors = HmisErrors::Errors.new
      errors.add :count, :required unless input.count.present?
      errors.add :count, :out_of_range, message: 'must be positive' if input.count&.negative?
      errors.add :count, :out_of_range, message: 'must be non-zero' if input.count&.zero?
      return { errors: errors.errors } if errors.any?

      # Create Units
      common = { user_id: current_user.id, created_at: Time.now, updated_at: Time.now }
      units = (1..input.count).map do
        Hmis::Unit.new(
          project_id: project.id,
          unit_type_id: unit_type&.id,
          **common,
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
