###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ServiceSortOption < Types::BaseEnum
    description 'HMIS Service Sorting Options'
    graphql_name 'ServiceSortOption'

    Hmis::Hud::HmisService::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt
    end
  end
end
