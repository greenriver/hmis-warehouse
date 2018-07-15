module WarehouseReports
  class TableauDashboardExportController < ApplicationController
    before_action :require_can_view_all_reports!

    def index
      @reports = report_source.all.order(created_at: :desc).page(params[:page]).per(25)
    end

    def running
      @reports = report_source.all.order(created_at: :desc).page(params[:page]).per(25)
    end

    #download
    def show
      @file = report_source.find(params[:id]).file
      send_data @file.content,
        type: @file.content_type,
        filename: File.basename(@file.file.to_s)
    end

    def create
      @report = report_source.create(report_params)
      job = Delayed::Job.enqueue Reporting::DashboardExportJob.new(coc_code: report_params[:coc_code], report_id: @report.id, current_user_id: current_user.id), queue: :high_priority
      @report.update(job_id: job.id)
      respond_with @report, location: warehouse_reports_tableau_dashboard_export_index_path
    end

    def destroy
    end

    def report_source
      GrdaWarehouse::DashboardExportReport
    end

    def report_params
      params.require(:report).permit(:coc_code).merge(user_id: current_user.id)
    end

    def flash_interpolation_options
      { resource_name: 'Report' }
    end
  end
end
