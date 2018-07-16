module Reporting
  class DashboardExportJob < ActiveJob::Base
    attr_accessor :coc_code
    attr_accessor :report_id

    queue_as :high_priority
    
    def initialize coc_code:, report_id:, current_user_id:
      GrdaWarehouse::DashboardExportReport.find(report_id).update(started_at: Time.now)
      
      @coc_code = coc_code
      @report_id = report_id
      @current_user_id = current_user_id
    end

    # Only try once, if we try again it erases previous failures since it doesn't bother to try since the previous run
    # is partially complete
    def max_attempts
      1 
    end
    
    def perform
      # Find the associated report generator
      if @coc_code.present?
        Exporters::Tableau.export_all(coc_code: @coc_code, report_id: @report_id)
      else
        Exporters::Tableau.export_all(report_id: @report_id)
      end
      NotifyUser.dashboard_export_report_finished(@current_user_id, @report_id).deliver_later
    end

    def enqueue(job)

    end
  end
end
