###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::RHYNumberofYears < Types::BaseEnum
    description 'R11.A'
    graphql_name 'RHYNumberofYears'
    value 'LESS_THAN_ONE_YEAR', '(1) Less than one year', value: 1
    value 'NUM_1_TO_2_YEARS', '(2) 1 to 2 years', value: 2
    value 'NUM_3_TO_5_OR_MORE_YEARS', '(3) 3 to 5 or more years', value: 3
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
