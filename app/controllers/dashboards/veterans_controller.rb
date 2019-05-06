module Dashboards
  class VeteransController < BaseController
    include ArelHelper

    before_action :require_can_view_censuses!

    def sub_population_key
      :veteran
    end
    helper_method :sub_population_key

    def active_report_class
      Reporting::MonthlyReports::Veteran
    end

  end
end