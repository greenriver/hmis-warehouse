###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module YouthParentsSubPop::Dashboards
  class YouthParentsController < ::Dashboards::BaseController
    include ArelHelper

    before_action :require_can_view_censuses!

    def sub_population_key
      :youth_parents
    end
    helper_method :sub_population_key

    def active_report_class
      YouthParentsSubPop::Reporting::MonthlyReports::YouthParents
    end
  end
end
