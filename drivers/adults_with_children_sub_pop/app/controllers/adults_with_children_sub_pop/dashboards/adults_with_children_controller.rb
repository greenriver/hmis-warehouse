###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultsWithChildrenSubPop::Dashboards
  class AdultsWithChildrenController < ::Dashboards::BaseController
    def sub_population_key
      :adults_with_children
    end
    helper_method :sub_population_key

    def active_report_class
      AdultsWithChildrenSubPop::Reporting::MonthlyReports::AdultsWithChildren
    end
  end
end
