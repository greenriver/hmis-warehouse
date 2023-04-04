###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class GenericReportJob < BaseJob
    include ArelHelper

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    # NOTE: instances of report_class must provide `title`, `url`, and `run_and_save!` methods
    # `title` should return a string suitable for an email subject
    # `run_and_save!` should run whatever calculations are necessary and save the results
    # `url` must provide a link to the individual report
    def perform(user_id:, report_class:, report_id:)
      klass = allowed_reports[report_class]
      if klass
        report = klass.find_by(id: report_id)
        # Occassionally people delete the report before it actually runs
        return unless report.present?

        report.run_and_save!

        NotifyUser.report_completed(user_id, report).deliver_later
      else
        setup_notifier('Generic Report Runner')
        msg = "Unable to run report, #{report_class} is not included in the allowed list of reports."
        @notifier.ping(msg) if @send_notifications
      end
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

      reports
    end
  end
end
