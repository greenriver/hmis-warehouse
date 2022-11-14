###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::NotEmployedReason < Types::BaseEnum
    description 'R6.B'
    graphql_name 'NotEmployedReason'
    value LOOKING_FOR_WORK, '(1) Looking for work', value: 1
    value UNABLE_TO_WORK, '(2) Unable to work', value: 2
    value NOT_LOOKING_FOR_WORK, '(3) Not looking for work', value: 3
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
