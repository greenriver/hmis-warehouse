###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteUnits < BaseMutation
    argument :unit_ids, [ID], required: true

    field :unit_ids, [ID], null: true

    def resolve(unit_ids:)
      units = Hmis::Unit.where(id: unit_ids)
      return { unit_ids: [], errors: [] } unless units.any?

      projects = units.pluck(:project_id).uniq
      errors = HmisErrors::Errors.new
      errors.add :base, :not_found if projects.empty?
      errors.add :base, :invalid, full_message: 'Cannot delete units across projects' if projects.size > 1
      return { errors: errors } if errors.any?

      project = Hmis::Hud::Project.find_by(id: projects&.first)
      errors.add :base, :not_found unless project.present?
      errors.add :base, :not_allowed unless current_user.permissions_for?(project, :can_manage_inventory)
      return { errors: errors } if errors.any?

      project.with_lock do
        units = Hmis::Unit.where(id: unit_ids).preload(:unit_type)
        unit_types = units.map(&:unit_type).uniq
        units.each(&:destroy!)
        unit_types.each do |unit_type|
          unit_type.track_availability(project_id: project_id, user_id: hmis_user.user_id)
        end
      end

      { unit_ids: unit_ids, errors: [] }
    end
  end
end
