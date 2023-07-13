###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CreateUnits < BaseMutation
    argument :input, Types::HmisSchema::UnitInput, required: true

    field :units, [Types::HmisSchema::Unit], null: true

    def resolve(input:)
      project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: input.project_id)

      errors = HmisErrors::Errors.new
      errors.add :project_id, :not_found unless project.present?
      errors.add :project_id, :not_allowed if project.present? && !current_user.permissions_for?(project, :can_manage_inventory)
      errors.add :count, :required unless input.count.present?
      errors.add :count, :out_of_range, message: 'must be positive' if input.count&.negative?
      errors.add :count, :out_of_range, message: 'must be non-zero' if input.count&.zero?
      unit_type = Hmis::UnitType.find_by(id: input.unit_type_id)
      errors.add :unit_type_id, :invalid if input.unit_type_id.present? && !unit_type.present?
      return { errors: errors.errors } if errors.any?

      # Create Units
      common = { user_id: hmis_user.user_id, created_at: Time.now, updated_at: Time.now }
      unit_attributes = (1..input.count).map do
        {
          project_id: project.id,
          unit_type_id: unit_type&.id,
          **common,
        }
      end

      units = Hmis::Unit.import!(unit_attributes)

      {
        units: units,
        errors: [],
      }
    end
  end
end
