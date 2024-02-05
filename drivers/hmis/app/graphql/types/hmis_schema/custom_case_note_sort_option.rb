###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CustomCaseNoteSortOption < Types::BaseEnum
    description 'HUD Custom Case Note Sorting Options'
    graphql_name 'CustomCaseNoteSortOption'

    Hmis::Hud::CustomCaseNote::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt, description: Hmis::Hud::CustomCaseNote::SORT_OPTION_DESCRIPTIONS[opt]
    end
  end
end
