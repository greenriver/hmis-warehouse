###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
      lock_obtained = HudReports::ReportInstance.with_advisory_lock(advisory_lock_name(report_class), timeout_seconds: 0) do
        report_completed = false
        klass = allowed_reports[report_class]
        if klass
          report = klass.find_by(id: report_id)
          # Occassionally people delete the report before it actually runs
          return unless report.present?

          report_completed = report.run_and_save!

          NotifyUser.report_completed(user_id, report).deliver_later
        else
          setup_notifier('Generic Report Runner')
          msg = "Unable to run report, #{report_class} is not included in the allowed list of reports."
          @notifier.ping(msg) if @send_notifications
        end
        report_completed
      end
      return if lock_obtained

      requeue_job(report_class)
    end

    private def advisory_lock_name(report_class)
      "generic_report_#{report_class}"
    end

    private def requeue_job(class_name)
      # Re-queue this repot before processing if another report is running for the same class
      # This should help prevent tying up delayed job workers when someone kicks off a dozen of the same report.
      a_t = Delayed::Job.arel_table
      job_object = Delayed::Job.where(a_t[:handler].matches("%job_id: #{job_id}%").or(a_t[:id].eq(job_id))).first
      return unless job_object

      Rails.logger.info("Report: #{class_name} already running...re-queuing job for #{WAIT_MINUTES} minutes from now")
      new_job = job_object.dup
      new_job.update(
        locked_at: nil,
        locked_by: nil,
        run_at: Time.current + WAIT_MINUTES.minutes,
        attempts: 0,
      )
    end

    def allowed_reports
      reports = {
        'GrdaWarehouse::WarehouseReports::Youth::Export' => ::GrdaWarehouse::WarehouseReports::Youth::Export,
        'Health::SsmExport' => ::Health::SsmExport,
        'Health::EncounterReport' => ::Health::EncounterReport,
        'GrdaWarehouse::WarehouseReports::TouchPoint' => ::GrdaWarehouse::WarehouseReports::TouchPoint,
        'GrdaWarehouse::WarehouseReports::ConfidentialTouchPoint' => GrdaWarehouse::WarehouseReports::ConfidentialTouchPoint,
        'GrdaWarehouse::WarehouseReports::Exports::AdHoc' => GrdaWarehouse::WarehouseReports::Exports::AdHoc,
        'GrdaWarehouse::WarehouseReports::Exports::AdHocAnon' => GrdaWarehouse::WarehouseReports::Exports::AdHocAnon,
      }

      reports['ProjectPassFail::ProjectPassFail'] = ProjectPassFail::ProjectPassFail if RailsDrivers.loaded.include?(:project_pass_fail)
      reports['ProjectScorecard::Report'] = ProjectScorecard::Report if RailsDrivers.loaded.include?(:project_scorecard)
      reports['BostonProjectScorecard::Report'] = BostonProjectScorecard::Report if RailsDrivers.loaded.include?(:boston_project_scorecard)
      if RailsDrivers.loaded.include?(:public_reports)
        reports['PublicReports::PointInTime'] = PublicReports::PointInTime
        reports['PublicReports::PitByMonth'] = PublicReports::PitByMonth
        reports['PublicReports::NumberHoused'] = PublicReports::NumberHoused
        reports['PublicReports::HomelessCount'] = PublicReports::HomelessCount
        reports['PublicReports::HomelessCountComparison'] = PublicReports::HomelessCountComparison
        reports['PublicReports::HomelessPopulation'] = PublicReports::HomelessPopulation
        reports['PublicReports::StateLevelHomelessness'] = PublicReports::StateLevelHomelessness
      end
      reports['IncomeBenefitsReport::Report'] = IncomeBenefitsReport::Report if RailsDrivers.loaded.include?(:income_benefits_report)
      if RailsDrivers.loaded.include?(:claims_reporting)
        reports['ClaimsReporting::EngagementTrends'] = ClaimsReporting::EngagementTrends
        reports['ClaimsReporting::QualityMeasures'] = ClaimsReporting::QualityMeasures
      end
      reports['HapReport::Report'] = HapReport::Report if RailsDrivers.loaded.include?(:hap_report)
      reports['PerformanceMetrics::Report'] = PerformanceMetrics::Report if RailsDrivers.loaded.include?(:performance_metrics)
      reports['HomelessSummaryReport::Report'] = HomelessSummaryReport::Report if RailsDrivers.loaded.include?(:homeless_summary_report)
      reports['PerformanceMeasurement::Report'] = PerformanceMeasurement::Report if RailsDrivers.loaded.include?(:performance_measurement)
      reports['LongitudinalSpm::Report'] = LongitudinalSpm::Report if RailsDrivers.loaded.include?(:longitudinal_spm)
      reports['CePerformance::Report'] = CePerformance::Report if RailsDrivers.loaded.include?(:ce_performance)
      reports['TxClientReports::ResearchExport'] = TxClientReports::ResearchExport if RailsDrivers.loaded.include?(:tx_client_reports)
      reports['HmisDataQualityTool::Report'] = HmisDataQualityTool::Report if RailsDrivers.loaded.include?(:hmis_data_quality_tool)
      reports['MaYyaReport::Report'] = MaYyaReport::Report if RailsDrivers.loaded.include?(:ma_yya_report)
      reports['MaReports::MonthlyPerformance::Report'] = MaReports::MonthlyPerformance::Report if RailsDrivers.loaded.include?(:ma_reports)
      reports['SystemPathways::Report'] = SystemPathways::Report if RailsDrivers.loaded.include?(:system_pathways)
      reports['AllNeighborsSystemDashboard::Report'] = AllNeighborsSystemDashboard::Report if RailsDrivers.loaded.include?(:all_neighbors_system_dashboard)

      reports
    end
  end
end
