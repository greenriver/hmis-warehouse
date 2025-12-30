###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteFunder < BaseMutation
    argument :id, ID, required: true

    field :funder, Types::HmisSchema::Funder, null: true

    def resolve(id:)
      record = Hmis::Hud::Funder.viewable_by(current_user).find_by(id: id)
      access_denied! unless record && policy_for(record.project, policy_type: :hmis_project).can_edit?

      record.destroy!
      {
        funder: record,
      }
    end
  end
end
