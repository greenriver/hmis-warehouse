module Dashboards
  class FamiliesController < BaseController
    include ArelHelper

    before_action :require_can_view_censuses!

    def sub_population_key
      :family
    end
    helper_method :sub_population_key

    def active_report_class
      Reporting::MonthlyReports::Family
    end
  end
end