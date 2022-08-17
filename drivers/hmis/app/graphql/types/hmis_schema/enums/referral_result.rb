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

    Hmis::Hud::Event.referral_result_enum_map.members.each do |member|
      value to_enum_key(member[:key]), member[:desc], value: member[:value]
    end
  end
end
