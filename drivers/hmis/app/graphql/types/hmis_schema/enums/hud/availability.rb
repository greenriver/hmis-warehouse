###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::Availability < Types::BaseEnum
    description '2.7.4'
    graphql_name 'Availability'
    value YEAR_ROUND, '(1) Year-round', value: 1
    value SEASONAL, '(2) Seasonal', value: 2
    value OVERFLOW, '(3) Overflow', value: 3
  end
end
