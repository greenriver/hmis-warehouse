###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::SSVFService < Types::BaseEnum
    description 'HUD SSVFService (V2.2)'
    graphql_name 'SSVFService'

    with_enum_map Hmis::Hud::Service.s_s_v_f_service_enum_map
  end
end
