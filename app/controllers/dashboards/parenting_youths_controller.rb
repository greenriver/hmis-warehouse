module Dashboards
  class ParentingYouthsController < BaseController
    include ArelHelper

    before_action :require_can_view_censuses!

    def sub_population_key
      :parenting_youth
    end
    helper_method :sub_population_key

    def active_report_class
      Reporting::MonthlyReports::ParentingYouth
    end
  end
end