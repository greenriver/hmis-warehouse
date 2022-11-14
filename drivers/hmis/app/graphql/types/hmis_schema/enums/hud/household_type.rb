###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::HouseholdType < Types::BaseEnum
    description '2.7.2'
    graphql_name 'HouseholdType'
    value HOUSEHOLDS_WITHOUT_CHILDREN, '(1) Households without children', value: 1
    value HOUSEHOLDS_WITH_AT_LEAST_ONE_ADULT_AND_ONE_CHILD, '(3) Households with at least one adult and one child', value: 3
    value HOUSEHOLDS_WITH_ONLY_CHILDREN, '(4) Households with only children', value: 4
  end
end
