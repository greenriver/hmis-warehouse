###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::TrackingMethod < Types::BaseEnum
    description '2.5.1'
    graphql_name 'TrackingMethod'
    value ENTRY_EXIT_DATE, '(0) Entry/Exit Date', value: 0
    value NIGHT_BY_NIGHT, '(3) Night-by-Night', value: 3
  end
end
