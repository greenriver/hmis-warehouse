###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
