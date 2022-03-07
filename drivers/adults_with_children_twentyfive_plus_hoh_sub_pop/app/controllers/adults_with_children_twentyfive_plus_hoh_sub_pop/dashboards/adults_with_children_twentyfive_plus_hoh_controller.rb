###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultsWithChildrenTwentyfivePlusHohSubPop::Dashboards
  class AdultsWithChildrenTwentyfivePlusHohController < ::Dashboards::BaseController
    def sub_population_key
      :adults_with_children_twentyfive_plus_hoh
    end
    helper_method :sub_population_key

    def active_report_class
      AdultsWithChildrenTwentyfivePlusHohSubPop::Reporting::MonthlyReports::AdultsWithChildrenTwentyfivePlusHoh
    end
  end
end
