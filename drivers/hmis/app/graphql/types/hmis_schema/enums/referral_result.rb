###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ReferralResult < Types::BaseEnum
    description 'HUD ReferralResult'
    graphql_name 'ReferralResult'

    with_enum_map Hmis::Hud::Event.referral_result_enum_map
  end
end
