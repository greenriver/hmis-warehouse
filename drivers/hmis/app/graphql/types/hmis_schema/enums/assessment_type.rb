###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::AssessmentType < Types::BaseEnum
    description 'HUD AssessmentType'
    graphql_name 'AssessmentType'

    with_enum_map Hmis::Hud::Assessment.assessment_types_enum_map
  end
end
