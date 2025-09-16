###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralParticipantInput < Types::BaseInputObject
    argument :user_id, ID, required: true
    argument :swimlane_id, ID, required: true

    # ...other
  end
end
