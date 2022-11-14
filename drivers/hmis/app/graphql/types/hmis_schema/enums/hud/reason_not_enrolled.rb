###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::ReasonNotEnrolled < Types::BaseEnum
    description 'P3.A'
    graphql_name 'ReasonNotEnrolled'
    value CLIENT_WAS_FOUND_INELIGIBLE_FOR_PATH, '(1) Client was found ineligible for PATH', value: 1
    value CLIENT_WAS_NOT_ENROLLED_FOR_OTHER_REASON_S, '(2) Client was not enrolled for other reason(s)', value: 2
  end
end
