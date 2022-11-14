###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::AssessmentLevel < Types::BaseEnum
    description '4.19.4'
    graphql_name 'AssessmentLevel'
    value CRISIS_NEEDS_ASSESSMENT, '(1) Crisis Needs Assessment', value: 1
    value HOUSING_NEEDS_ASSESSMENT, '(2) Housing Needs Assessment', value: 2
  end
end
