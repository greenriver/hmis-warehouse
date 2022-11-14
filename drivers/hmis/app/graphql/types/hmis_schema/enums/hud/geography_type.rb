###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::GeographyType < Types::BaseEnum
    description '2.8.7'
    graphql_name 'GeographyType'
    value 'URBAN', '(1) Urban', value: 1
    value 'SUBURBAN', '(2) Suburban', value: 2
    value 'RURAL', '(3) Rural', value: 3
    value 'UNKNOWN_DATA_NOT_COLLECTED', '(99) Unknown / data not collected', value: 99
  end
end
