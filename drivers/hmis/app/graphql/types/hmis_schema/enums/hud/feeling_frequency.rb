###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::FeelingFrequency < Types::BaseEnum
    description 'C1.2'
    graphql_name 'FeelingFrequency'
    value 'NOT_AT_ALL', '(0) Not at all', value: 0
    value 'ONCE_A_MONTH', '(1) Once a month', value: 1
    value 'SEVERAL_TIMES_A_MONTH', '(2) Several times a month', value: 2
    value 'SEVERAL_TIMES_A_WEEK', '(3) Several times a week', value: 3
    value 'AT_LEAST_EVERY_DAY', '(4) At least every day', value: 4
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_REFUSED', '(9) Client refused', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
