###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::NameDataQuality < Types::BaseEnum
    description 'HUD Name Data Quality'
    graphql_name 'NameDataQuality'

    Hmis::Hud::Client.name_data_quality_enum_map.members.each do |member|
      value "NAME_#{to_enum_key(member[:key])}", member[:desc], value: member[:value]
    end
  end
end
