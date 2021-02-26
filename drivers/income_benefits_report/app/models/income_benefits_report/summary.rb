###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  IncomeBenefitsReport::Summary
  extend ActiveSupport::Concern
  included do
    def summary_data
      @summary_data ||= Rails.cache.fetch(cache_key_for_section('summary'), expires_in: expiration_length) do
        {
          'Total Stayer Households' => clients.stayers(filter.end_date).heads_of_household.count,
          'Stayer Adults' => clients.stayers(filter.end_date).adults.count,
          'Stayer Children' => clients.stayers(filter.end_date).children.count,
          'Total Leaver Households' => clients.leavers(filter.end_date).heads_of_household.count,
          'Leaver Adults' => clients.leavers(filter.end_date).adults.count,
          'Leaver Children' => clients.leavers(filter.end_date).children.count,
        }
      end
    end
  end
end
