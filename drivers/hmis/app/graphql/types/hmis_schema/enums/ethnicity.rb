###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::Ethnicity < Types::BaseEnum
    description 'HUD Ethnicity'
    graphql_name 'Ethnicity'

    Hmis::Hud::Client.ethnicity_enum_map.members.each do |member|
      value "ETHNICITY_#{to_enum_key(member[:key])}", member[:desc], value: member[:value]
    end
  end
end
