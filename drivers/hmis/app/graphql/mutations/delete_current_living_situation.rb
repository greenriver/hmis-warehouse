###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteCurrentLivingSituation < BaseMutation
    argument :id, ID, required: true

    field :current_living_situation, Types::HmisSchema::CurrentLivingSituation, null: true

    def resolve(id:)
      record = Hmis::Hud::CurrentLivingSituation.viewable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :current_living_situation, permissions: [:can_edit_enrollments])
    end
  end
end
