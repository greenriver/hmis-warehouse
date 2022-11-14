###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::ExitAction < Types::BaseEnum
    description '4.36.1'
    graphql_name 'ExitAction'
    value NO, '(0) No', value: 0
    value YES, '(1) Yes', value: 1
    value CLIENT_REFUSED, '(9) Client refused', value: 9
  end
end
