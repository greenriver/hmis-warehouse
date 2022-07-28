###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::Gender < Types::BaseEnum
    description 'HUD Gender'
    graphql_name 'Gender'

    value 'GENDER_FEMALE', 'Female', value: 0
    value 'GENDER_MALE', 'Male', value: 1
    value 'GENDER_NO_SINGLE_GENDER', 'A gender that is not singularly ‘Female’ or ‘Male’', value: 4
    value 'GENDER_TRANSGENDER', 'Transgender', value: 5
    value 'GENDER_QUESTIONING', 'Questioning', value: 6
    value 'GENDER_UNKNOWN', 'Client doesn\'t know', value: 8
    value 'GENDER_REFUSED', 'Client refused', value: 9
    value 'GENDER_NOT_COLLECTED', 'Data not collected', value: 99
  end
end
