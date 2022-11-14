###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::CountExchangeForSex < Types::BaseEnum
    description 'R15.B'
    graphql_name 'CountExchangeForSex'
    value NUM_1_3, '(1) 1-3', value: 1
    value NUM_4_7, '(2) 4-7', value: 2
    value NUM_8_11, '(3) 8-11', value: 3
    value NUM_12_OR_MORE, '(4) 12 or more', value: 4
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
