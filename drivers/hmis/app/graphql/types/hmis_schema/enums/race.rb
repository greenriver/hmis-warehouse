###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::Race < Types::BaseEnum
    description 'HUD Race (1.7)'
    graphql_name 'Race'

    with_enum_map Hmis::Hud::Client.race_enum_map, prefix: 'RACE_'
  end
end
