###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteProjectCoc < BaseMutation
    argument :id, ID, required: true

    field :project_coc, Types::HmisSchema::ProjectCoc, null: true

    def resolve(id:)
      record = Hmis::Hud::ProjectCoc.viewable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :project_coc, permissions: [:can_edit_project_details])
    end
  end
end
