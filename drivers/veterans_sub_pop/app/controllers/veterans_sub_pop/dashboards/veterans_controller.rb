###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module VeteransSubPop::Dashboards
  class VeteransController < ::Dashboards::BaseController
    def sub_population_key
      :veterans
    end
    helper_method :sub_population_key

    def active_report_class
      VeteransSubPop::Reporting::MonthlyReports::Veterans
    end
  end
end
