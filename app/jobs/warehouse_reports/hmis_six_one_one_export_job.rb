module WarehouseReports
  class HmisSixOneOneExportJob < ActiveJob::Base
    include ArelHelper

    queue_as :hmis_six_one_one_export

    def perform options, report_url: warehouse_reports_hmis_exports_url
      options = options.with_indifferent_access
      report = Exporters::HmisSixOneOne::Base.new(
        start_date: options[:start_date],
        end_date: options[:end_date],
        projects: options[:projects],
        period_type: options[:period_type],
        directive: options[:directive],
        hash_status: options[:hash_status],
        include_deleted: options[:include_deleted],
        user_id: options[:user_id]
      ).export!
      NotifyUser.hmis_export_finished(options[:user_id], report.id, report_url: report_url).deliver_later
    end

    def log msg, underline: false
      return unless Rails.env.development?
      Rails.logger.info msg
      Rails.logger.info "="*msg.length if underline
    end


  end
end