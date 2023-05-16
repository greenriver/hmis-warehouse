###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::HouseholdSortOption < Types::BaseEnum
    description 'HUD Household Sorting Options'
    graphql_name 'HouseholdSortOption'

    Hmis::Hud::Household::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt
    end
  end
end
