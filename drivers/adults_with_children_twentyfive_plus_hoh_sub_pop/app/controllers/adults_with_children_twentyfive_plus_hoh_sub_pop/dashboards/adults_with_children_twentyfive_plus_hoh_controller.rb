###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AdultsWithChildrenTwentyfivePlusHohSubPop::Dashboards
  class AdultsWithChildrenTwentyfivePlusHohController < ::Dashboards::BaseController
    def sub_population_key
      :adults_with_children_twentyfive_plus_hoh
    end
    helper_method :sub_population_key

    def active_report_class
      AdultsWithChildrenTwentyfivePlusHohSubPop::Reporting::MonthlyReports::AdultsWithChildrenTwentyfivePlusHoh
    end
  end
end
