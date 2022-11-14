###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::HealthStatus < Types::BaseEnum
    description 'R7.1'
    graphql_name 'HealthStatus'
    value 'EXCELLENT', '(1) Excellent', value: 1
    value 'VERY_GOOD', '(2) Very good', value: 2
    value 'GOOD', '(3) Good', value: 3
    value 'FAIR', '(4) Fair', value: 4
    value 'POOR', '(5) Poor', value: 5
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_REFUSED', '(9) Client refused', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
