###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientsSubPop::Dashboards
  class ClientsController < ::Dashboards::BaseController
    def sub_population_key
      :clients
    end
    helper_method :sub_population_key

    def active_report_class
      ClientsSubPop::Reporting::MonthlyReports::Clients
    end
  end
end
