###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::IncarceratedAdult < Types::BaseEnum
    description 'V7.I'
    graphql_name 'IncarceratedAdult'
    value 'NOT_INCARCERATED', '(0) Not incarcerated', value: 0
    value 'INCARCERATED_ONCE', '(1) Incarcerated once', value: 1
    value 'INCARCERATED_TWO_OR_MORE_TIMES', '(2) Incarcerated two or more times', value: 2
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
