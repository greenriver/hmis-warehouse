###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::AssessmentType < Types::BaseEnum
    description '4.19.3'
    graphql_name 'AssessmentType'
    value PHONE, '(1) Phone', value: 1
    value VIRTUAL, '(2) Virtual', value: 2
    value IN_PERSON, '(3) In Person', value: 3
  end
end
