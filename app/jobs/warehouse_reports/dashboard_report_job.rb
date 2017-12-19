module WarehouseReports
  class DashboardReportJob < ActiveJob::Base
    include ArelHelper

    queue_as :dashboard_active_report

    def perform report_type, sub_population
      klass = GrdaWarehouse::WarehouseReports::Dashboard::Base.sub_populations_by_type[report_type.to_sym][sub_population.to_sym]
      report = klass.new
      report.started_at = DateTime.now
      report.parameters = klass.params      

      report.data = report.run!

      report.finished_at = DateTime.now
      
      report.save

    end

    def log msg, underline: false
      return unless Rails.env.development?
      Rails.logger.info msg
      Rails.logger.info "="*msg.length if underline
    end
    
    
  end
end