module WarehouseReports::Health
  class AgencyPerformanceController < ApplicationController
    include ArelHelper
    include PjaxModalController
    include WindowClientPathGenerator
    include WarehouseReportAuthorization

    before_action :require_can_view_aggregate_health!
    before_action :require_can_administer_health!
    before_action :set_dates, only: [:index]

    def index
      @report = Health::AgencyPerformance.new(range: (@start_date..@end_date))

      @agencies = @report.agency_counts()
      @totals = @report.total_counts()
    end

    def detail
      @agency_id = params[:agency_id]&.to_i
      @section = params[:section]
      @patient_ids = params[:patient_ids]&.map(&:to_i)
      @patients = Health::Patient.bh_cp.where(id: @patient_ids).
        order(last_name: :asc, first_name: :asc).
        pluck(:client_id, :first_name, :last_name).map do |client_id, first_name, last_name|
          OpenStruct.new(
            client_id: client_id,
            first_name: first_name,
            last_name: last_name
          )
      end

      @agency = Health::Agency.find(@agency_id)

    end

    def set_dates
      @start_date = 1.months.ago.beginning_of_month.to_date
      @end_date = @start_date.end_of_month

      @start_date = params[:filter].try(:[], :start_date).presence || @start_date
      @end_date = params[:filter].try(:[], :end_date).presence || @end_date

      if @start_date.to_date > @end_date.to_date
        new_start = @end_date
        @end_date = @start_date
        @start_date = new_start
      end
    end
  end
end