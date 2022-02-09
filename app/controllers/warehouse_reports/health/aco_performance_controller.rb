###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class AcoPerformanceController < ApplicationController
    include ArelHelper
    include ClientPathGenerator
    include WarehouseReportAuthorization

    before_action :require_can_view_aggregate_health!
    before_action :require_can_administer_health!
    before_action :set_aco, only: [:index]
    before_action :set_report_year, only: [:index]

    def index
      @report = Health::AcoPerformance.new(@aco, @report_year) unless @aco.zero?
    end

    def report_periods
      @report_periods = begin
        periods = {
          "9/2/#{Date.current.prev_year.year} to 9/1/#{Date.current.year}" => Date.current.prev_year.year,
        }

        if Date.current >= Date.new(Date.current.year, 9, 2)
          periods.merge!(
            {
              "9/2/#{Date.current.year} to 9/1/#{Date.current.next_year.year}" => Date.current.year,
            },
          )
        end
        periods
      end
    end
    helper_method :report_periods

    def default_period
      report_periods.values.last
    end
    helper_method :default_period

    def set_aco
      @aco = params.dig(:filter, :aco).to_i
      @aco_name = Health::AccountableCareOrganization.find(@aco)&.name unless @aco.zero?
    end

    def set_report_year
      @report_year = params.dig(:filter, :year).to_i
      @report_year = default_period if @report_year.zero?
    end
  end
end
