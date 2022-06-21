###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class YouthExportController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_filter, only: [:index, :create]
    before_action :set_report, only: [:show, :destroy]

    def index
      @reports = report_scope.order(created_at: :desc).
        select(:id, :user_id, :options, :client_count, :started_at, :completed_at, :created_at)
      @pagy, @reports = pagy(@reports)
    end

    def create
      @report = GrdaWarehouse::WarehouseReports::Youth::Export.create(options: filter_params, user_id: current_user.id)
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
          filename = "Youth Export #{Time.current.to_s.delete(',')}.xlsx"
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
      @filter = ::Filters::FilterBase.new(filter_params)
    end

    private def filter_params
      @filter_params = { user_id: current_user.id }
      @filter_params.merge!(report_params[:filter]) if report_params[:filter].present?
      @filter_params
    end

    private def report_scope
      GrdaWarehouse::WarehouseReports::Youth::Export.where(user_id: current_user.id)
    end

    private def report_params
      params.permit(
        filter: [
          :start,
          :end,
          :start_age,
          :end_age,
          project_ids: [],
          organization_ids: [],
          data_source_ids: [],
          cohort_ids: [],
        ],
      )
    end

    def flash_interpolation_options
      { resource_name: 'Youth Export' }
    end
  end
end
