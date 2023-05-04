###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteUnits < BaseMutation
    argument :unit_ids, [ID], required: true

    field :ids, [ID], null: true

    def resolve(unit_ids:)
      units = Hmis::Unit.where(id: unit_ids)
      return { ids: [], errors: [] } unless units.any?

      projects = units.pluck(:project_id).uniq
      errors = HmisErrors::Error.new
      errors.add :base, :not_found if projects.empty?
      errors.add :base, :invalid, full_message: 'Cannot delete units across projects' if projects.size > 1
      return { errors: errors } if errors.any?

      project = Hmis::Hud::Project.find_by(id: projects&.first)
      errors.add :base, :not_found unless project.present?
      errors.add :base, :not_allowed unless current_user.permissions_for?(project, :can_edit_project_details)
      return { errors: errors } if errors.any?

      Hmis::Unit.where(id: unit_ids).destroy_all

      { ids => unit_ids, errors: [] }
    end
  end
end
