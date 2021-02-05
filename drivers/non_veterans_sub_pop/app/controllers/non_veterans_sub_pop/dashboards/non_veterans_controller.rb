###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module NonVeteransSubPop::Dashboards
  class NonVeteransController < ::Dashboards::BaseController
    def sub_population_key
      :non_veterans
    end
    helper_method :sub_population_key

    def active_report_class
      NonVeteransSubPop::Reporting::MonthlyReports::NonVeterans
    end
  end
end
