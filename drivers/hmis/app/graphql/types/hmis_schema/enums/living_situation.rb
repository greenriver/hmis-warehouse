###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::LivingSituation < Types::BaseEnum
    description 'HUD LivingSituation (3.917.1)'
    graphql_name 'LivingSituation'

    with_enum_map Hmis::Hud::Enrollment.living_situations_enum_map
  end
end
