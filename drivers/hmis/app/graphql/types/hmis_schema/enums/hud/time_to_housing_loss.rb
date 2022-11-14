###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::TimeToHousingLoss < Types::BaseEnum
    description 'V7.A'
    graphql_name 'TimeToHousingLoss'
    value 'NUM_1_6_DAYS', '(0) 1-6 days', value: 0
    value 'NUM_7_13_DAYS', '(1) 7-13 days', value: 1
    value 'NUM_14_21_DAYS', '(2) 14-21 days', value: 2
    value 'MORE_THAN_21_DAYS', '(3) More than 21 days', value: 3
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
