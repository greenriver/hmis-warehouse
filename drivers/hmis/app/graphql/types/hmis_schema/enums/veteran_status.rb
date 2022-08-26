###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::VeteranStatus < Types::BaseEnum
    description 'HUD Veteran Status (1.8)'
    graphql_name 'VeteranStatus'

    with_enum_map Hmis::Hud::Client.veteran_status_enum_map, prefix: 'VETERAN_STATUS_'
  end
end
