module WarehouseReports::Health
  class AgencyPerformanceController < ApplicationController
    include ArelHelper
    before_action :require_can_view_aggregate_health!
    before_action :require_can_administer_health!

    def index
      start_date = 1.months.ago.beginning_of_month.to_date
      end_date = start_date.end_of_month
      @report = Health::AgencyPerformance.new(range: (start_date..end_date))

      @agencies = @report.agency_counts()


    end
  end
end