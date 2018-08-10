module WarehouseReports::Health
  class AgencyPerformanceController < ApplicationController
    include ArelHelper
    before_action :require_can_view_aggregate_health!
    before_action :require_can_administer_health!

    def index
      @report = Health::AgencyPerformance.new(range: (1.months.ago..Date.today))

      @agencies = @report.agencies()

      @patient_referrals = @report.patient_referrals
      @consent_dates = @report.consent_dates
      @ssm_dates


    end
  end
end