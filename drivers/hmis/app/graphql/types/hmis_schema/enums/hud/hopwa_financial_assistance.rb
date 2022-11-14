###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::HOPWAFinancialAssistance < Types::BaseEnum
    description 'V2.3'
    graphql_name 'HOPWAFinancialAssistance'
    value 'RENTAL_ASSISTANCE', '(1) Rental assistance', value: 1
    value 'SECURITY_DEPOSITS', '(2) Security deposits', value: 2
    value 'UTILITY_DEPOSITS', '(3) Utility deposits', value: 3
    value 'UTILITY_PAYMENTS', '(4) Utility payments', value: 4
    value 'MORTGAGE_ASSISTANCE', '(7) Mortgage assistance', value: 7
  end
end
