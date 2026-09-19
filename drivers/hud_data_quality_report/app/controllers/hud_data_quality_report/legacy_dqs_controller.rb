###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudDataQualityReport
  class LegacyDqsController < ApplicationController
    include WarehouseReportAuthorization

    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'hud_reports/dqs')
    end

    LEGACY_DQ_TYPES = (1..7).map { |n| "Reports::DataQuality::Fy2017::Q#{n}" }.freeze

    def index
      @reports = report_source.where(type: LEGACY_DQ_TYPES).order(name: :asc)
    end

    def show
      @report = report_source.find(params[:id].to_i)
      @results = report_results(@report.id).
        select(*report_result_summary_columns)
      @pagy, @results = pagy(@results)
    end

    def report_source
      Report
    end

    def report_result_source
      ReportResult
    end

    private def report_results(report_id)
      report_result_source.runs_visible_to(current_user).
        joins(:user).
        where(report_id: report_id)
    end

    private def report_result_summary_columns
      report_result_source.column_names - ['original_results', 'results', 'support', 'validations']
    end
  end
end
