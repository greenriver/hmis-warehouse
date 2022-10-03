###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::AssessmentSortOption < Types::BaseEnum
    description 'HUD Assessment Sorting Options'
    graphql_name 'AssessmentSortOption'

    Hmis::Hud::Assessment::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt
    end
  end
end
