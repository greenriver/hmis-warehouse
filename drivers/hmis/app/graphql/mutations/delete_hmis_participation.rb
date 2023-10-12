###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteHmisParticipation < BaseMutation
    argument :id, ID, required: true

    field :hmis_participation, Types::HmisSchema::HmisParticipation, null: true

    def resolve(id:)
      record = Hmis::Hud::HmisParticipation.viewable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :hmis_participation, permissions: [:can_edit_project_details])
    end
  end
end
