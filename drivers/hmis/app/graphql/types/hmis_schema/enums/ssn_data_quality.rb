###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::SSNDataQuality < Types::BaseEnum
    description 'HUD SSN Data Quality'
    graphql_name 'SSNDataQuality'

    Hmis::Hud::Client.ssn_data_quality_enum_map.members.each do |member|
      value "SSN_#{to_enum_key(member[:key])}", member[:desc], value: member[:value]
    end
  end
end
