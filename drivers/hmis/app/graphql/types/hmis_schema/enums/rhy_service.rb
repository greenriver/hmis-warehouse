###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::RHYService < Types::BaseEnum
    description 'HUD RHYService (R14.2)'
    graphql_name 'RHYService'

    with_enum_map Hmis::Hud::Service.r_h_y_service_enum_map
  end
end
