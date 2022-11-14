###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::SSVFFinancialAssistance < Types::BaseEnum
    description '4.15.B'
    graphql_name 'SSVFFinancialAssistance'
    value 'RENTAL_ASSISTANCE', '(1) Rental assistance', value: 1
    value 'SECURITY_DEPOSIT', '(2) Security deposit', value: 2
    value 'UTILITY_DEPOSIT', '(3) Utility deposit', value: 3
    value 'UTILITY_FEE_PAYMENT_ASSISTANCE', '(4) Utility fee payment assistance', value: 4
    value 'MOVING_COSTS', '(5) Moving costs', value: 5
    value 'TRANSPORTATION_SERVICES_TOKENS_VOUCHERS', '(8) Transportation services: tokens/vouchers', value: 8
    value 'TRANSPORTATION_SERVICES_VEHICLE_REPAIR_MAINTENANCE', '(9) Transportation services: vehicle repair/maintenance', value: 9
    value 'CHILD_CARE', '(10) Child care', value: 10
    value 'GENERAL_HOUSING_STABILITY_ASSISTANCE_EMERGENCY_SUPPLIES', '(11) General housing stability assistance - emergency supplies', value: 11
    value 'GENERAL_HOUSING_STABILITY_ASSISTANCE', '(12) General housing stability assistance', value: 12
    value 'EMERGENCY_HOUSING_ASSISTANCE', '(14) Emergency housing assistance', value: 14
    value 'EXTENDED_SHALLOW_SUBSIDY_RENTAL_ASSISTANCE', '(15) Extended Shallow Subsidy - Rental Assistance', value: 15
    value 'FOOD_ASSISTANCE', '(16) Food Assistance', value: 16
  end
end
