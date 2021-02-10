###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultOnlyHouseholdsSubPop::Dashboards
  class AdultOnlyHouseholdsController < ::Dashboards::BaseController
    def sub_population_key
      :adult_only_households
    end
    helper_method :sub_population_key

    def active_report_class
      AdultOnlyHouseholdsSubPop::Reporting::MonthlyReports::AdultOnlyHouseholds
    end
  end
end
