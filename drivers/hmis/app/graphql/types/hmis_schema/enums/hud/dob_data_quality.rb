###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::DOBDataQuality < Types::BaseEnum
    description '3.3.2'
    graphql_name 'DOBDataQuality'
    value 'FULL_DOB_REPORTED', '(1) Full DOB reported', value: 1
    value 'APPROXIMATE_OR_PARTIAL_DOB_REPORTED', '(2) Approximate or partial DOB reported', value: 2
    value 'CLIENT_DOESN_T_KNOW', "(8) Client doesn't know", value: 8
    value 'CLIENT_REFUSED', '(9) Client refused', value: 9
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
