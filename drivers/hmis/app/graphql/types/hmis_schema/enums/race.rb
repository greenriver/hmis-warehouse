###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::Race < Types::BaseEnum
    description 'HUD Race (1.7)'
    graphql_name 'Race'

    with_enum_map Hmis::Hud::Client.race_enum_map
  end
end
