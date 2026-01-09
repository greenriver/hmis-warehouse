###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteCeParticipation < BaseMutation
    argument :id, ID, required: true

    field :ce_participation, Types::HmisSchema::CeParticipation, null: true

    def resolve(id:)
      record = Hmis::Hud::CeParticipation.viewable_by(current_user).find_by(id: id)
      access_denied! unless record && policy_for(record.project, policy_type: :hmis_project).can_edit?

      record.destroy!

      {
        ce_participation: record,
      }
    end
  end
end
