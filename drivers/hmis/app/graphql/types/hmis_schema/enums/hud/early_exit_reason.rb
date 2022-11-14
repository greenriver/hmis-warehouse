###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::EarlyExitReason < Types::BaseEnum
    description '4.37.A'
    graphql_name 'EarlyExitReason'
    value LEFT_FOR_OTHER_OPPORTUNITIES_INDEPENDENT_LIVING, '(1) Left for other opportunities - independent living', value: 1
    value LEFT_FOR_OTHER_OPPORTUNITIES_EDUCATION, '(2) Left for other opportunities - education', value: 2
    value LEFT_FOR_OTHER_OPPORTUNITIES_MILITARY, '(3) Left for other opportunities - military', value: 3
    value LEFT_FOR_OTHER_OPPORTUNITIES_OTHER, '(4) Left for other opportunities - other', value: 4
    value NEEDS_COULD_NOT_BE_MET_BY_PROJECT, '(5) Needs could not be met by project', value: 5
  end
end
