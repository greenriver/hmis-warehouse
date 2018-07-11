module WarehouseReports
  class TableauDashboardExportController < ApplicationController
    before_action :require_can_view_all_reports!

    def index
      @reports = GrdaWarehouse::DashboardExportReport.all
    end
    
    def show 
      #download
    end
    
    def create
      @report = GrdaWarehouse::DashboardExportReport.create(coc_code: report_params[:coc_code])
      job = Delayed::Job.enqueue Reporting::DashboardExportJob.new(coc_code: report_params[:coc_code], report_id: @report.id), queue: :high_priority
      @report.update(job_id: job.id)
      respond_with @report, location: warehouse_reports_tableau_dashboard_export_index_path
    end
    
    def destroy 
    end

    def report_source
      GrdaWarehouse::DashboardExportReport
    end
    
    def report_params
      params.require(:report).permit(:coc_code)
    end
    
    def flash_interpolation_options
      { resource_name: 'Report' }
    end
  end
end
