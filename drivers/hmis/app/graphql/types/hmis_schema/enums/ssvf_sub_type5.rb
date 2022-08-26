###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::SSVFSubType5 < Types::BaseEnum
    description 'HUD SSVFSubType5'
    graphql_name 'SSVFSubType5'

    with_enum_map Hmis::Hud::Service.s_s_v_f_sub_type5_enum_map
  end
end
