###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class AcoPerformanceController < ApplicationController
    include ArelHelper
    include WindowClientPathGenerator
    include WarehouseReportAuthorization

    before_action :require_can_view_aggregate_health!
    before_action :require_can_administer_health!
    before_action :set_aco, only: [:index]
    before_action :set_dates, only: [:index]

    def index
      @report = Health::AcoPerformance.new(aco: @aco, range: (@start_date..@end_date)) if @aco
    end

    def set_aco
      @aco = params.dig(:filter, :aco)
    end

    def set_dates
      @start_date = Date.current.beginning_of_month.to_date
      @end_date = @start_date.end_of_month

      @start_date = params[:filter].try(:[], :start_date).presence&.to_date || @start_date
      @end_date = params[:filter].try(:[], :end_date).presence&.to_date || @end_date

      return unless @start_date.to_date > @end_date.to_date

      new_start = @end_date
      @end_date = @start_date
      @start_date = new_start
    end
  end
end
