###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteCeEvent < BaseMutation
    argument :id, ID, required: true

    field :ce_event, Types::HmisSchema::Event, null: true

    def resolve(id:)
      record = Hmis::Hud::Event.viewable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :ce_event, permissions: [:can_edit_enrollments])
    end
  end
end
