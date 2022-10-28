###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::TimesHomelessPastThreeYears < Types::BaseEnum
    description 'HUD TimesHomelessPastThreeYears (3.917.4)'
    graphql_name 'TimesHomelessPastThreeYears'

    with_enum_map Hmis::Hud::Enrollment.times_homeless_past_three_years_enum_map, prefix: 'TIMES_'
  end
end
