###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::ExportDirective < Types::BaseEnum
    description '1.2'
    graphql_name 'ExportDirective'
    value 'DELTA_REFRESH', '(1) Delta refresh', value: 1
    value 'FULL_REFRESH', '(2) Full refresh', value: 2
    value 'OTHER', '(3) Other', value: 3
  end
end
