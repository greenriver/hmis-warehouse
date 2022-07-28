###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::VeteranStatus < Types::BaseEnum
    description 'HUD Veteran Status'
    graphql_name 'VeteranStatus'

    Hmis::Hud::Client.veteran_status_enum_map.members.each do |member|
      value "VETERAN_STATUS_#{to_enum_key(member[:key])}", member[:desc], value: member[:value]
    end
  end
end
