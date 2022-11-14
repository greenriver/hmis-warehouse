###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::PATHSMIInformation < Types::BaseEnum
    description '4.9.E'
    graphql_name 'PATHSMIInformation'
    value 'NO', '(0) No', value: 0
    value 'UNCONFIRMED_PRESUMPTIVE_OR_SELF_REPORT', '(1) Unconfirmed; presumptive or self-report', value: 1
    value 'CONFIRMED_THROUGH_ASSESSMENT_AND_CLINICAL_EVALUATION', '(2) Confirmed through assessment and clinical evaluation', value: 2
    value 'CONFIRMED_BY_PRIOR_EVALUATION_OR_CLINICAL_RECORDS', '(3) Confirmed by prior evaluation or clinical records', value: 3
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_REFUSED', '(9) Client refused', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
