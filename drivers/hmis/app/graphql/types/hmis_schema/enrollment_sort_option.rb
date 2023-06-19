###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::EnrollmentSortOption < Types::BaseEnum
    description 'HUD Enrollment Sorting Options'
    graphql_name 'EnrollmentSortOption'

    Hmis::Hud::Enrollment::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt, description: Hmis::Hud::Enrollment::SORT_OPTION_DESCRIPTIONS[opt]
    end
  end
end
