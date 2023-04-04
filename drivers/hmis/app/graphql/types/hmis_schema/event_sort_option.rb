###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::EventSortOption < Types::BaseEnum
    description 'HUD Event Sorting Options'
    graphql_name 'EventSortOption'

    Hmis::Hud::Event::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt
    end
  end
end
