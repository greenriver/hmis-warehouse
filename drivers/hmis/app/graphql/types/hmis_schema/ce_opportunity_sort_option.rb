###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeOpportunitySortOption < Types::BaseEnum
    description 'Opportunity Sorting Options'

    Hmis::Ce::Opportunity::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt, description: Hmis::Ce::Opportunity::SORT_OPTION_DESCRIPTIONS[opt]
    end
  end
end
