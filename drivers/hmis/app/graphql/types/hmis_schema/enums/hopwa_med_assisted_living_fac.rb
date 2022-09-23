###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::HOPWAMedAssistedLivingFac < Types::BaseEnum
    description 'HUD HOPWAMedAssistedLivingFac (2.02.9)'
    graphql_name 'HOPWAMedAssistedLivingFac'

    with_enum_map Hmis::Hud::Project.h_o_p_w_a_med_assisted_living_facs_enum_map
  end
end
