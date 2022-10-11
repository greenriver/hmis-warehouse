###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::AssessmentLevel < Types::BaseEnum
    description 'HUD AssessmentLevel (4.19.4)'
    graphql_name 'AssessmentLevel'

    with_enum_map Hmis::Hud::Assessment.assessment_levels_enum_map
  end
end
