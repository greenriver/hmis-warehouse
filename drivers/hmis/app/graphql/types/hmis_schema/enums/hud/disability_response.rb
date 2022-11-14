###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::DisabilityResponse < Types::BaseEnum
    description '4.10.2'
    graphql_name 'DisabilityResponse'
    value NO, '(0) No', value: 0
    value ALCOHOL_USE_DISORDER, '(1) Alcohol use disorder', value: 1
    value DRUG_USE_DISORDER, '(2) Drug use disorder', value: 2
    value BOTH_ALCOHOL_AND_DRUG_USE_DISORDERS, '(3) Both alcohol and drug use disorders', value: 3
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
