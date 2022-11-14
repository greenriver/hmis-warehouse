###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::DependentUnder6 < Types::BaseEnum
    description 'V7.O'
    graphql_name 'DependentUnder6'
    value 'NO', '(0) No', value: 0
    value 'YOUNGEST_CHILD_IS_UNDER_1_YEAR_OLD', '(1) Youngest child is under 1 year old', value: 1
    value 'YOUNGEST_CHILD_IS_1_TO_6_YEARS_OLD_AND_OR_ONE_OR_MORE_CHILDREN_ANY_AGE_REQUIRE_SIGNIFICANT_CARE', '(2) Youngest child is 1 to 6 years old and/or one or more children (any age) require significant care', value: 2
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
