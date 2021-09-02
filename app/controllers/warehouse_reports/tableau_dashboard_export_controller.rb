###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class TableauDashboardExportController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_report, only: [:show, :destroy]

    def index
      @reports = report_source.all.order(created_at: :desc).page(params[:page]).per(25)
    end

    def running
      @reports = report_source.all.order(created_at: :desc).page(params[:page]).per(25)
    end

    # download
    def show
      @file = @report.file
      send_data @file.content,
                type: @file.content_type,
                filename: "#{@report.display_coc_code}.zip"
    end

    def create
      @report = report_source.create(report_params)
      job = Delayed::Job.enqueue Reporting::DashboardExportJob.new(coc_code: report_params[:coc_code], report_id: @report.id, current_user_id: current_user.id), queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
      @report.update(job_id: job.id)
      respond_with @report, location: warehouse_reports_tableau_dashboard_export_index_path
    end

    def destroy
      @report.destroy
      respond_with(@report, location: warehouse_reports_tableau_dashboard_export_index_path)
    end

    def report_source
      GrdaWarehouse::DashboardExportReport
    end

    def set_report
      @report = report_source.find params[:id].to_i
    end

    def report_params
      params.require(:report).permit(:coc_code).merge(user_id: current_user.id)
    end

    def flash_interpolation_options
      { resource_name: 'Report' }
    end
  end
end
