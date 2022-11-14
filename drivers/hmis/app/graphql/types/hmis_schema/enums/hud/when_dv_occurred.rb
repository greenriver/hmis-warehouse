###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::WhenDVOccurred < Types::BaseEnum
    description '4.11.A'
    graphql_name 'WhenDVOccurred'
    value WITHIN_THE_PAST_THREE_MONTHS, '(1) Within the past three months', value: 1
    value THREE_TO_SIX_MONTHS_AGO_EXCLUDING_SIX_MONTHS_EXACTLY, '(2) Three to six months ago (excluding six months exactly)', value: 2
    value SIX_MONTHS_TO_ONE_YEAR_AGO_EXCLUDING_ONE_YEAR_EXACTLY, '(3) Six months to one year ago (excluding one year exactly)', value: 3
    value ONE_YEAR_OR_MORE, '(4) One year or more', value: 4
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
