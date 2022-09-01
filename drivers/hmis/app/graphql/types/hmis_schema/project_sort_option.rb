###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ProjectSortOption < Types::BaseEnum
    description 'HUD Project Sorting Options'
    graphql_name 'ProjectSortOption'

    Hmis::Hud::Project::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt
    end
  end
end
