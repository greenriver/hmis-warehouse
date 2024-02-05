###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteCeParticipation < BaseMutation
    argument :id, ID, required: true

    field :ce_participation, Types::HmisSchema::CeParticipation, null: true

    def resolve(id:)
      record = Hmis::Hud::CeParticipation.viewable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :ce_participation, permissions: [:can_edit_project_details])
    end
  end
end
