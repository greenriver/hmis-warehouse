###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport
  class LegacySpmsController < BaseController
    before_action :require_can_view_hud_reports!

    LEGACY_REPORT_TYPES = [
      'Reports::SystemPerformance::Fy2019::MeasureOne',
      'Reports::SystemPerformance::Fy2019::MeasureTwo',
      'Reports::SystemPerformance::Fy2019::MeasureThree',
      'Reports::SystemPerformance::Fy2019::MeasureFour',
      'Reports::SystemPerformance::Fy2019::MeasureFive',
      'Reports::SystemPerformance::Fy2019::MeasureSix',
      'Reports::SystemPerformance::Fy2019::MeasureSeven',
    ].freeze

    def index
      @reports = report_source.where(type: LEGACY_REPORT_TYPES).order(name: :asc)
    end

    def show
      @report = report_source.find(params[:id].to_i)
      @results = report_results(@report.id).
        select(*report_result_summary_columns).
        page(params[:page].to_i).per(20)
    end

    def report_source
      Report
    end

    def report_result_source
      ReportResult
    end

    private def report_results(report_id)
      report_result_source.viewable_by(current_user).
        joins(:user).
        where(report_id: report_id)
    end

    private def report_result_summary_columns
      report_result_source.column_names - ['original_results', 'results', 'support', 'validations']
    end
  end
end
