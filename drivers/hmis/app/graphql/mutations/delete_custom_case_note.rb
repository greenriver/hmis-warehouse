###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteCustomCaseNote < CleanBaseMutation
    argument :id, ID, required: true

    field :custom_case_note, Types::HmisSchema::CustomCaseNote, null: true

    def resolve(id:)
      record = Hmis::Hud::CustomCaseNote.viewable_by(current_user).find_by(id: id)
      access_denied! unless record && policy_for(record.enrollment, policy_type: :hmis_enrollment).can_edit?

      record.destroy!
      {
        custom_case_note: record,
        errors: [],
      }
    end
  end
end
