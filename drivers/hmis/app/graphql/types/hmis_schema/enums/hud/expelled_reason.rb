###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::ExpelledReason < Types::BaseEnum
    description 'R17.A'
    graphql_name 'ExpelledReason'
    value 'CRIMINAL_ACTIVITY_DESTRUCTION_OF_PROPERTY_VIOLENCE', '(1) Criminal activity/destruction of property/violence', value: 1
    value 'NON_COMPLIANCE_WITH_PROJECT_RULES', '(2) Non-compliance with project rules', value: 2
    value 'NON_PAYMENT_OF_RENT_OCCUPANCY_CHARGE', '(3) Non-payment of rent/occupancy charge', value: 3
    value 'REACHED_MAXIMUM_TIME_ALLOWED_BY_PROJECT', '(4) Reached maximum time allowed by project', value: 4
    value 'PROJECT_TERMINATED', '(5) Project terminated', value: 5
    value 'UNKNOWN_DISAPPEARED', '(6) Unknown/disappeared', value: 6
  end
end
