###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports
  class GenericReportJob < BaseJob
    include ArelHelper

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    WAIT_MINUTES = 10

    # NOTE: instances of report_class must provide `title`, `url`, and `run_and_save!` methods
    # `title` should return a string suitable for an email subject
    # `run_and_save!` should run whatever calculations are necessary and save the results
    # `url` must provide a link to the individual report
    def perform(user_id:, report_class:, report_id:)
      # Attempt to acquire an advisory lock to ensure only one instance of this report class runs at a time.
      # If the lock is already held by another worker, the job will be postponed.
      lock_acquired = false
      execution_result = GrdaWarehouseBase.with_advisory_lock(advisory_lock_name(report_class), timeout_seconds: 0) do
        lock_acquired = true
        run_report(user_id, report_class, report_id)
      end

      return execution_result if lock_acquired

      requeue_at(
        Time.current + WAIT_MINUTES.minutes,
        "Report: #{report_class} already running (advisory lock contention)...re-queuing job for #{WAIT_MINUTES} minutes from now",
      )
      false
    end

    private def run_report(user_id, report_class, report_id)
      klass = allowed_reports[report_class]
      unless klass
        setup_notifier('Generic Report Runner')
        msg = "Unable to run report, #{report_class} is not included in the allowed list of reports."
        @notifier.ping(msg) if @send_notifications
        return false
      end

      report = klass.find_by(id: report_id)
      # occasionally people delete the report before it actually runs
      return false unless report.present?

      completed = report.run_and_save!
      NotifyUser.report_completed(user_id, report).deliver_later
      completed
    end

    private def advisory_lock_name(report_class)
      "generic_report_#{report_class}"
    end

    def allowed_reports
      reports = {
        'GrdaWarehouse::WarehouseReports::Youth::Export' => ::GrdaWarehouse::WarehouseReports::Youth::Export,
        'GrdaWarehouse::WarehouseReports::TouchPoint' => ::GrdaWarehouse::WarehouseReports::TouchPoint,
        'GrdaWarehouse::WarehouseReports::Exports::AdHoc' => GrdaWarehouse::WarehouseReports::Exports::AdHoc,
        'GrdaWarehouse::WarehouseReports::Exports::AdHocAnon' => GrdaWarehouse::WarehouseReports::Exports::AdHocAnon,
      }

      reports['ProjectPassFail::ProjectPassFail'] = ProjectPassFail::ProjectPassFail
      reports['ProjectScorecard::Report'] = ProjectScorecard::Report
      reports['BostonProjectScorecard::Report'] = BostonProjectScorecard::Report
      reports['PublicReports::PointInTime'] = PublicReports::PointInTime
      reports['PublicReports::PitByMonth'] = PublicReports::PitByMonth
      reports['PublicReports::NumberHoused'] = PublicReports::NumberHoused
      reports['PublicReports::HomelessCount'] = PublicReports::HomelessCount
      reports['PublicReports::HomelessCountComparison'] = PublicReports::HomelessCountComparison
      reports['PublicReports::HomelessPopulation'] = PublicReports::HomelessPopulation
      reports['PublicReports::StateLevelHomelessness'] = PublicReports::StateLevelHomelessness
      reports['IncomeBenefitsReport::Report'] = IncomeBenefitsReport::Report
      reports['HapReport::Report'] = HapReport::Report
      reports['PerformanceMetrics::Report'] = PerformanceMetrics::Report
      reports['HomelessSummaryReport::Report'] = HomelessSummaryReport::Report
      reports['PerformanceMeasurement::Report'] = PerformanceMeasurement::Report
      reports['LongitudinalSpm::Report'] = LongitudinalSpm::Report
      reports['CePerformance::Report'] = CePerformance::Report
      reports['TxClientReports::ResearchExport'] = TxClientReports::ResearchExport
      reports['HmisDataQualityTool::Report'] = HmisDataQualityTool::Report
      reports['MaYyaReport::Report'] = MaYyaReport::Report
      reports['MaReports::MonthlyPerformance::Report'] = MaReports::MonthlyPerformance::Report
      reports['SystemPathways::Report'] = SystemPathways::Report
      reports['AllNeighborsSystemDashboard::Report'] = AllNeighborsSystemDashboard::Report

      reports
    end
  end
end
