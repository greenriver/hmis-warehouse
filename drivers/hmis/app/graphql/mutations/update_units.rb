###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateUnits < BaseMutation
    argument :project_id, ID, required: true
    argument :unit_ids, [ID], required: true
    argument :name, String, required: false

    field :units, [Types::HmisSchema::Unit], null: false

    def resolve(project_id:, unit_ids:, name:)
      project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: project_id)
      raise 'Not found' unless project.present?
      raise 'Access denied' unless current_user.permissions_for?(project, :can_manage_units)

      units = project.units.where(id: unit_ids)
      units.update_all(name: name, user_id: current_user.id, updated_at: Time.current)

      { units: units, errors: [] }
    end
  end
end
