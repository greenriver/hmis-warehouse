###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class AgencyPerformanceController < ApplicationController
    include ArelHelper
    include AjaxModalRails::Controller
    include ClientPathGenerator
    include WarehouseReportAuthorization

    before_action :require_can_view_aggregate_health!
    before_action :require_can_administer_health!
    before_action :set_dates, only: [:index]

    def index
      query_string = {
        start_date: @start_date,
        end_date: @end_date,
      }.to_query
      @pdf_export = Health::DocumentExports::AgencyPerformanceExport.new(query_string: query_string)

      @agency_report = Health::AgencyPerformance.new(range: (@start_date..@end_date))
      @agencies = @agency_report.agency_counts
      @agency_totals = @agency_report.total_counts
    end

    def detail
      agency_name = params.require(:entity)[:entity_id]
      @section = params.require(:entity)[:section]
      @patient_ids = params.require(:entity)[:patient_ids].split(',')&.map(&:to_i)
      @patients = Health::Patient.bh_cp.where(id: @patient_ids).
        preload(:care_coordinator).
        order(last_name: :asc, first_name: :asc)

      @agency = Health::Agency.find_by(name: agency_name)
    end

    def describe_computations
      path = 'app/views/warehouse_reports/health/agency_performance/README.md'
      description = File.read(path)
      markdown = Redcarpet::Markdown.new(::TranslatedHtml)
      markdown.render(description)
    end
    helper_method :describe_computations

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
