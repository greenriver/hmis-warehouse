###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::AssessmentSortOption < Types::BaseEnum
    description 'HUD Assessment Sorting Options'
    graphql_name 'AssessmentSortOption'

    Hmis::Hud::CustomAssessment::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt, description: Hmis::Hud::Assessment::SORT_OPTION_DESCRIPTIONS[opt]
    end
  end
end
