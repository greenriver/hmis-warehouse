###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty
  class ExportJob < ::BaseJob
    include ::ArelHelper

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(options, report_url: warehouse_reports_hmis_exports_url)
      options = options.with_indifferent_access
      report = HmisCsvTwentyTwenty::Exporter::Base.new(
        start_date: options[:start_date],
        end_date: options[:end_date],
        projects: options[:projects],
        period_type: options[:period_type],
        directive: options[:directive],
        hash_status: options[:hash_status],
        include_deleted: options[:include_deleted],
        faked_pii: options[:faked_pii],
        user_id: options[:user_id],
        version: options[:version],
      ).export!

      if (recurring_hmis_export = recurring_hmis_export(options))
        ::GrdaWarehouse::RecurringHmisExportLink.create(hmis_export_id: report.id, recurring_hmis_export_id: recurring_hmis_export.id, exported_at: Date.current)
        recurring_hmis_export.store(report) if recurring_hmis_export.s3_valid?
      end

      NotifyUser.hmis_export_finished(options[:user_id], report.id, report_url: report_url).deliver_later if report_url.present?
    end

    def log(msg, underline: false)
      return unless Rails.env.development?

      Rails.logger.info msg
      Rails.logger.info '=' * msg.length if underline
    end

    def recurring_hmis_export(options)
      recurring_hmis_export = options[:recurring_hmis_export_id]
      return nil if recurring_hmis_export.zero?

      ::GrdaWarehouse::RecurringHmisExport.find(recurring_hmis_export)
    end
  end
end
