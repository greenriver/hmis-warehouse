###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::NameDataQuality < Types::BaseEnum
    description '3.1.5'
    graphql_name 'NameDataQuality'
    value FULL_NAME_REPORTED, '(1) Full name reported', value: 1
    value PARTIAL_STREET_NAME_OR_CODE_NAME_REPORTED, '(2) Partial, street name, or code name reported', value: 2
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
