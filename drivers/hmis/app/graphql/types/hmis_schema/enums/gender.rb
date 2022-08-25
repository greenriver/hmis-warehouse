###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::Gender < Types::BaseEnum
    description 'HUD Gender'
    graphql_name 'Gender'

    Hmis::Hud::Client.gender_enum_map.members.each do |member|
      value "GENDER_#{to_enum_key(member[:key])}", "(#{member[:value]}) #{member[:desc]}", value: member[:value]
    end
  end
end
