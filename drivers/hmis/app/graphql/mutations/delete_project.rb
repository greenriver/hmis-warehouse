###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteProject < BaseMutation
    argument :id, ID, required: true

    field :project, Types::HmisSchema::Project, null: true

    def resolve(id:)
      record = Hmis::Hud::Project.viewable_by(current_user).find_by(id: id)
      access_denied! unless record && policy_for(record, policy_type: :hmis_project).can_destroy?

      # While this is redundant with the checks above, this check caches the authorization result so that
      # the project object-level authorization check will succeed even after the project has been deleted
      access_denied! unless current_permission?(permission: :can_view_project, entity: record)

      record.destroy!
      {
        project: record,
      }
    end
  end
end
