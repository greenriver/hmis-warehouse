###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::PercentAMI < Types::BaseEnum
    description 'V4.1'
    graphql_name 'PercentAMI'
    value LESS_THAN_30, '(1) Less than 30%', value: 1
    value NUM_30_TO_50, '(2) 30% to 50%', value: 2
    value GREATER_THAN_50, '(3) Greater than 50%', value: 3
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
