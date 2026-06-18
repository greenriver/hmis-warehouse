###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
