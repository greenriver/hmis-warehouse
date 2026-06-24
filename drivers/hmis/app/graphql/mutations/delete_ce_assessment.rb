###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteCeAssessment < BaseMutation
    argument :id, ID, required: true

    field :ce_assessment, Types::HmisSchema::CeAssessment, null: true

    def resolve(id:)
      record = Hmis::Hud::Assessment.viewable_by(current_user).find_by(id: id)
      access_denied! unless record && policy_for(record.enrollment, policy_type: :hmis_enrollment).can_edit?

      record.destroy!
      {
        ce_assessment: record,
        errors: [],
      }
    end
  end
end
