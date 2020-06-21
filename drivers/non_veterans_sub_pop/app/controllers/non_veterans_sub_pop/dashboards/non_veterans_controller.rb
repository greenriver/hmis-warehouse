###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module NonVeteransSubPop::Dashboards
  class NonVeteransController < ::Dashboards::BaseController
    include ArelHelper

    before_action :require_can_view_censuses!

    def sub_population_key
      :non_veterans
    end
    helper_method :sub_population_key

    def active_report_class
      NonVeteransSubPop::Reporting::MonthlyReports::NonVeterans
    end
  end
end
