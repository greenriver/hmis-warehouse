###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::LengthOfStay < Types::BaseEnum
    description 'HUD Length of Stay in Prior living situation (3.917.2)'
    graphql_name 'LengthOfStay'

    with_enum_map Hmis::Hud::Enrollment.length_of_stays_enum_map, prefix: 'LOS_'
  end
end
