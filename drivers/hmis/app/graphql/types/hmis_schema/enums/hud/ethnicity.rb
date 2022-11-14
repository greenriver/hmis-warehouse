###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::Ethnicity < Types::BaseEnum
    description '3.5.1'
    graphql_name 'Ethnicity'
    value 'NON_HISPANIC_NON_LATIN_A_O_X', '(0) Non-Hispanic/Non-Latin(a)(o)(x)', value: 0
    value 'HISPANIC_LATIN_A_O_X', '(1) Hispanic/Latin(a)(o)(x)', value: 1
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_REFUSED', '(9) Client refused', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
