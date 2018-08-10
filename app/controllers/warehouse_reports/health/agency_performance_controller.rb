module WarehouseReports::Health
  class AgencyPerformanceController < ApplicationController
    include ArelHelper
    before_action :require_can_view_aggregate_health!
    before_action :require_can_administer_health!

    def index
      @report = Health::AgencyPerformance.new(range: (1.months.ago.to_date..Date.today))

      @agencies = @report.agency_counts()


    end
  end
end