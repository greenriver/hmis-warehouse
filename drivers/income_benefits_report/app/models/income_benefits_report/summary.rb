###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  IncomeBenefitsReport::Summary
  extend ActiveSupport::Concern
  included do
    def summary_data
      stayer_scope = clients.date_range(report_date_range).stayers(filter.end_date)
      leaver_scope = clients.date_range(report_date_range).leavers(filter.end_date)
      {
        'Total Stayer Households' => stayer_scope.heads_of_household.count,
        'Stayer Adults' => stayer_scope.adults.count,
        'Stayer Children' => stayer_scope.children.count,
        'Total Leaver Households' => leaver_scope.heads_of_household.count,
        'Leaver Adults' => leaver_scope.adults.count,
        'Leaver Children' => leaver_scope.children.count,
      }
    end
  end
end
