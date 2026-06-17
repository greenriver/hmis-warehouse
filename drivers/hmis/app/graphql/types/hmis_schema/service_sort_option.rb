###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ServiceSortOption < Types::BaseEnum
    description 'HMIS Service Sorting Options'
    graphql_name 'ServiceSortOption'

    Hmis::Hud::HmisService::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt, description: Hmis::Hud::HmisService::SORT_OPTION_DESCRIPTIONS[opt]
    end
  end
end
