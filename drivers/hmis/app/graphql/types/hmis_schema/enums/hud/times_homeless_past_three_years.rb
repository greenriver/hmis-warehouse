###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::TimesHomelessPastThreeYears < Types::BaseEnum
    description '3.3917.4'
    graphql_name 'TimesHomelessPastThreeYears'
    value ONE_TIME, '(1) One time', value: 1
    value TWO_TIMES, '(2) Two times', value: 2
    value THREE_TIMES, '(3) Three times', value: 3
    value FOUR_OR_MORE_TIMES, '(4) Four or more times', value: 4
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
