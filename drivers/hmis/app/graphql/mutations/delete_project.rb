###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteProject < BaseMutation
    argument :id, ID, required: true

    field :project, Types::HmisSchema::Project, null: true

    def resolve(id:)
      record = Hmis::Hud::Project.viewable_by(current_user).find_by(id: id)

      # While this is redundant with the viewable_by() scope above, this check caches the authorization result so that
      # the project object-level authorization check will succeed even after the project has been deleted
      access_denied! unless current_permission?(permission: :can_view_project, entity: record)

      default_delete_record(record: record, field_name: :project, permissions: :can_delete_project)
    end
  end
end
