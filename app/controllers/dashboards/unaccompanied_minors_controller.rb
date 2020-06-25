###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Dashboards
  class UnaccompaniedMinorsController < BaseController
    include ArelHelper

    before_action :require_can_view_censuses!

    def sub_population_key
      :unaccompanied_minors
    end
    helper_method :sub_population_key

    def active_report_class
      Reporting::MonthlyReports::UnaccompaniedMinors
    end
  end
end
