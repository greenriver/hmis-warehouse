###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Reports
  class ArchiveAndPurgeReportJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(report_class:, report_id:)
      # Ensure driver models are loaded so archival registries (HudReportArchival.generator_registry,
      # Rails.application.config.report_archival_types) are populated. The DJ worker is a separate
      # process from the rake task and does not call eager_load! on its own when eager_load is false.
      Rails.application.eager_load! unless Rails.application.config.eager_load

      klass = report_class.safe_constantize
      unless klass
        Rails.logger.warn("#{self.class.name}: unknown report class #{report_class.inspect}, skipping")
        return
      end

      report = klass.find_by(id: report_id)
      unless report
        Rails.logger.warn("#{self.class.name}: #{report_class} ##{report_id} not found, skipping")
        return
      end

      lock_name = "#{self.class.name}-#{report_class}-#{report_id}"
      acquired = false
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0) do
        acquired = true
        result = report.archive_and_purge!
        unless result[:success]
          report.update_archival_metadata('purge_failed_at', Time.current.iso8601)
          report.update_archival_metadata('purge_failure_reason', result[:errors].join(', '))
          raise "#{self.class.name}: failed for #{report_class} ##{report_id}: #{result[:errors].inspect}"
        end

        Rails.logger.info("#{self.class.name}: completed for #{report_class} ##{report_id}: #{result.inspect}")
      end

      Rails.logger.warn("#{self.class.name}: skipping #{report_class} ##{report_id} — lock already held by another worker") unless acquired
    end
  end
end
