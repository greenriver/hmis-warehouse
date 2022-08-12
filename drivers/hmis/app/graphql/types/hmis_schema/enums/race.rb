###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::Race < Types::BaseEnum
    description 'HUD Race'
    graphql_name 'Race'

    Hmis::Hud::Client.race_enum_map.members.each do |member|
      value "RACE_#{to_enum_key(member[:key])}", member[:desc], value: member[:value]
    end
  end
end
