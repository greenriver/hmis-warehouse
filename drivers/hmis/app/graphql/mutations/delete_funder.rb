###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteFunder < BaseMutation
    argument :id, ID, required: true

    field :funder, Types::HmisSchema::Funder, null: true

    def resolve(id:)
      record = Hmis::Hud::Funder.viewable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :funder, permissions: [:can_edit_project_details])
    end
  end
end
