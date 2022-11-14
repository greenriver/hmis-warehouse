###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::CrisisServicesUse < Types::BaseEnum
    description '4.49.1'
    graphql_name 'CrisisServicesUse'
    value NUM_0, '(0) 0', value: 0
    value NUM_1_2, '(1) 1-2', value: 1
    value NUM_3_5, '(2) 3-5', value: 2
    value NUM_6_10, '(3) 6-10', value: 3
    value NUM_11_20, '(4) 11-20', value: 4
    value MORE_THAN_20, '(5) More than 20', value: 5
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
