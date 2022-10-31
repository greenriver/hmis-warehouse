###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::MonthsHomelessPastThreeYears < Types::BaseEnum
    description 'HUD MonthsHomelessPastThreeYears (3.917.5)'
    graphql_name 'MonthsHomelessPastThreeYears'

    with_enum_map Hmis::Hud::Enrollment.months_homeless_past_three_years_enum_map, prefix: 'MONTHS_'
  end
end
