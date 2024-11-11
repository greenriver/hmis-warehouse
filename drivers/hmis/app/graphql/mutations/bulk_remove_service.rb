###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class BulkRemoveService < CleanBaseMutation
    argument :project_id, ID, required: true
    argument :service_ids, [ID], required: true, description: 'HmisService ids to remove'

    field :success, Boolean, null: true

    def resolve(project_id:, service_ids:)
      project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: project_id)
      access_denied! unless project
      access_denied! unless current_permission?(permission: :can_edit_enrollments, entity: project)

      services = Hmis::Hud::HmisService.with_project(project_id).where(id: service_ids).map(&:owner)
      # Note: we are intentionally NOT raising an error if some services are not found.
      # They may have already been removed by another user or in another window, which we can gracefully ignore.

      Hmis::Hud::Service.transaction { services.each(&:destroy!) }

      { success: true }
    end
  end
end
