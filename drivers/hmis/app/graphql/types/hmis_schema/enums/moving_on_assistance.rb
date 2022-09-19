###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::MovingOnAssistance < Types::BaseEnum
    description 'HUD MovingOnAssistance (C2.2)'
    graphql_name 'MovingOnAssistance'

    with_enum_map Hmis::Hud::Service.moving_on_assistance_enum_map
  end
end
