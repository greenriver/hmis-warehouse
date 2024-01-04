###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CompleteDisabilityResponse < Types::BaseEnum
    graphql_name 'CompleteDisabilityResponse'
    # Used for Disability.DisabiltiyResponse field. It is a combination of DisabilityResponse+NoYesMissing enums,
    # with a special fake value for ALCOHOL_USE_DISORDERS which is the only one that overlaps with a different label.

    SUBSTANCE_USE_1_OVERRIDE_VALUE = 10

    value 'NO', 'No', value: 0
    value 'YES', 'Yes', value: 1
    value 'ALCOHOL_USE_DISORDER', 'Alcohol use disorder', value: SUBSTANCE_USE_1_OVERRIDE_VALUE # The HUD value is 1.
    value 'DRUG_USE_DISORDER', 'Drug use disorder', value: 2
    value 'BOTH_ALCOHOL_AND_DRUG_USE_DISORDERS', 'Both alcohol and drug use disorders', value: 3
    value 'CLIENT_DOESN_T_KNOW', 'Client doesn\'t know', value: 8
    value 'CLIENT_PREFERS_NOT_TO_ANSWER', 'Client prefers not to answer', value: 9
    value 'DATA_NOT_COLLECTED', 'Data not collected', value: 99
    invalid_value
  end
end
