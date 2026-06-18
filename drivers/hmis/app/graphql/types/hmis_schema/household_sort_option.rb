###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::HouseholdSortOption < Types::BaseEnum
    description 'HUD Household Sorting Options'
    graphql_name 'HouseholdSortOption'

    Hmis::Hud::Household::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt, description: Hmis::Hud::Household::SORT_OPTION_DESCRIPTIONS[opt]
    end
  end
end
