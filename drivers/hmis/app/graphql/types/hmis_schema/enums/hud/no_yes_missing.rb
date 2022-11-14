###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::NoYesMissing < Types::BaseEnum
    description '1.7'
    graphql_name 'NoYesMissing'
    value 'NO', '(0) No', value: 0
    value 'YES', '(1) Yes', value: 1
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
