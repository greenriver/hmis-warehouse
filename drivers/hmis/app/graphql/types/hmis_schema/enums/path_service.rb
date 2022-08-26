###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::PATHService < Types::BaseEnum
    description 'HUD PATHService'
    graphql_name 'PATHService'

    with_enum_map Hmis::Hud::Service.p_a_t_h_service_enum_map
  end
end
