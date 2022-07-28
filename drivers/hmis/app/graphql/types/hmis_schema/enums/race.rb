###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::Race < Types::BaseEnum
    description 'HUD Race'
    graphql_name 'Race'

    value 'RACE_AM_IND_AK_NATIVE', 'American Indian, Alaska Native, or Indigenous', value: 1
    value 'RACE_ASIAN', 'Asian or Asian American', value: 2
    value 'RACE_BLACK_AF_AMERICAN', 'Black, African-American, or African', value: 3
    value 'RACE_NATIVE_HI_PACIFIC', 'Native Hawaiian or Pacific Islander', value: 4
    value 'RACE_WHITE', 'White', value: 5
    value 'RACE_UNKNOWN', 'Client doesn\'t know', value: 8
    value 'RACE_REFUSED', 'Client refused', value: 9
    value 'RACE_NOT_COLLECTED', 'Data not collected', value: 99
  end
end
