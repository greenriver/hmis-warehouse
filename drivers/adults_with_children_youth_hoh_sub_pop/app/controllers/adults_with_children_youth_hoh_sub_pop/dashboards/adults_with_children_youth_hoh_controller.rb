###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AdultsWithChildrenYouthHohSubPop::Dashboards
  class AdultsWithChildrenYouthHohController < ::Dashboards::BaseController
    def sub_population_key
      :adults_with_children_youth_hoh
    end
    helper_method :sub_population_key

    def active_report_class
      AdultsWithChildrenYouthHohSubPop::Reporting::MonthlyReports::AdultsWithChildrenYouthHoh
    end
  end
end
