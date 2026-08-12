###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module LongitudinalSpm
  class RestoreSpmsJob < ApplicationJob
    queue_as :default

    def perform(report_id:)
      report = LongitudinalSpm::Report.find(report_id)
      targets = report.purged_spms.map(&:hud_spm)

      targets.each(&:begin_restore!)

      targets.each do |spm|
        result = ::HudReports::RestoreArchivedReportDataService.new(spm).restore!
        if result[:success]
          spm.finish_restore!
        else
          message = Array.wrap(result[:errors]).join(', ')
          Rails.logger.error("LongitudinalSpm::RestoreSpmsJob: SPM ##{spm.id} restore failed: #{message}")
          spm.fail_restore!(message)
        end
      end
    ensure
      begin
        targets&.each do |spm|
          spm.reload
          spm.fail_restore!('Restore did not complete') if spm.restoring?
        end
      rescue StandardError => e
        Rails.logger.error("LongitudinalSpm::RestoreSpmsJob: failed to clear restore state for report ##{report_id}: #{e.message}")
      end
    end
  end
end
