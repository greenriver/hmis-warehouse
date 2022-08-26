###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::EventType < Types::BaseEnum
    description 'HUD EventType (4.20.2)'
    graphql_name 'EventType'

    with_enum_map Hmis::Hud::Event.events_enum_map
  end
end
