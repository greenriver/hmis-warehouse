###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Dashboards
  class ParentingChildrensController < BaseController
    include ArelHelper

    before_action :require_can_view_censuses!

    def sub_population_key
      :parenting_children
    end
    helper_method :sub_population_key

    def active_report_class
      Reporting::MonthlyReports::ParentingChildren
    end
  end
end
