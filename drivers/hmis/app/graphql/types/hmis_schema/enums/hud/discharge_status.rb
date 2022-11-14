###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::DischargeStatus < Types::BaseEnum
    description 'V1.12'
    graphql_name 'DischargeStatus'
    value 'HONORABLE', '(1) Honorable', value: 1
    value 'GENERAL_UNDER_HONORABLE_CONDITIONS', '(2) General under honorable conditions', value: 2
    value 'BAD_CONDUCT', '(4) Bad conduct', value: 4
    value 'DISHONORABLE', '(5) Dishonorable', value: 5
    value 'UNDER_OTHER_THAN_HONORABLE_CONDITIONS_OTH', '(6) Under other than honorable conditions (OTH)', value: 6
    value 'UNCHARACTERIZED', '(7) Uncharacterized', value: 7
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_REFUSED', '(9) Client refused', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
