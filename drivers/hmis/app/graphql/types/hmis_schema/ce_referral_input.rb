###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Deprecated, since the CreateReferral mutation no longer requires extra input besides the opportunity ID and client ID.
module Types
  class HmisSchema::CeReferralInput < Types::BaseInputObject
    argument :participants, [Types::HmisSchema::CeReferralParticipantInput], required: true

    # ...other referral properties?
  end
end
