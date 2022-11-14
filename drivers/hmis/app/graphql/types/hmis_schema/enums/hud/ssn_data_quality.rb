###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::SSNDataQuality < Types::BaseEnum
    description '3.2.2'
    graphql_name 'SSNDataQuality'
    value 'FULL_SSN_REPORTED', '(1) Full SSN reported', value: 1
    value 'APPROXIMATE_OR_PARTIAL_SSN_REPORTED', '(2) Approximate or partial SSN reported', value: 2
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_REFUSED', '(9) Client refused', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
