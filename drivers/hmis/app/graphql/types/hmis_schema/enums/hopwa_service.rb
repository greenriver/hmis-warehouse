###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::HOPWAService < Types::BaseEnum
    description 'HUD HOPWAService (W1.2)'
    graphql_name 'HOPWAService'

    with_enum_map Hmis::Hud::Service.h_o_p_w_a_service_enum_map
  end
end
