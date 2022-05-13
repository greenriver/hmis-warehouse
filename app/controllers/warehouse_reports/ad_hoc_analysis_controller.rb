###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class AdHocAnalysisController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_filter, only: [:index, :create]
    before_action :set_report, only: [:show, :destroy]

    def index
      @reports = report_scope.order(created_at: :desc).
        select(*report_source.index_columns)
      @pagy, @reports = pagy(@reports)
    end

    def create
      @report = report_source.create(options: filter_params, user_id: current_user.id)
      GenericReportJob.perform_later(
        user_id: current_user.id,
        report_class: @report.class.name,
        report_id: @report.id,
      )
      respond_with(@report, location: @report.url)
    end

    def show
      respond_to do |format|
        format.xlsx do
          filename = "Ad-Hoc Export #{Time.current.to_s.delete(',')}.xlsx"
          render(xlsx: 'show', filename: filename)
        end
      end
    end

    def destroy
      @report.destroy
      respond_with(@report, location: @report.url)
    end

    private def set_report
      @report = report_scope.find(params[:id])
    end

    private def set_filter
      @filter = ::Filters::DateRangeAndSourcesResidentialOnly.new(filter_params)
    end

    private def filter_params
      @filter_params = { user_id: current_user.id }
      @filter_params.merge!(report_params[:filter]) if report_params[:filter].present?
      @filter_params[:start_age] = report_params.dig(:filter, :start_age) || 0
      @filter_params[:end_age] = report_params.dig(:filter, :end_age) || 100
      @filter_params[:start] = report_params.dig(:filter, :start) || Date.current.last_year.beginning_of_year
      @filter_params[:end] = report_params.dig(:filter, :end) || Date.current.last_year.end_of_year

      @filter_params
    end

    private def report_scope
      report_source.where(user_id: current_user.id)
    end

    private def report_source
      GrdaWarehouse::WarehouseReports::Exports::AdHoc
    end

    private def report_params
      params.permit(
        filter: [
          :start,
          :end,
          :start_age,
          :end_age,
          :sub_population,
          project_ids: [],
          organization_ids: [],
          data_source_ids: [],
        ],
      )
    end

    def flash_interpolation_options
      { resource_name: 'Ad-Hoc Export' }
    end
  end
end
