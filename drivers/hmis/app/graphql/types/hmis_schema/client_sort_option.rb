###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ClientSortOption < Types::BaseEnum
    description 'HUD Client Sorting Options'
    graphql_name 'ClientSortOption'

    Hmis::Hud::Client::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt, description: Hmis::Hud::Client::SORT_OPTION_DESCRIPTIONS[opt]
    end
  end
end
