###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports
  # Base DocumentExport model for HUD report cell detail exports.
  # Handles authorization, execution orchestration, and descriptive title generation.
  #
  # Subclasses must implement:
  # - builder: Returns a CellDetailExportBuilder instance
  class CellDetailExportBase < ::GrdaWarehouse::DocumentExport
    def authorized?
      # User must have HUD report permissions AND either own the report or have view-all permission
      user.can_view_hud_reports? && (report.user_id == user_id || user.can_view_all_hud_reports?)
    end

    def perform
      with_status_progression do
        result = builder.call

        self.filename = result.filename
        self.file_data = result.data
        self.mime_type = DocumentExportBehavior::EXCEL_MIME_TYPE
      end
    end

    def download_title
      generator = builder.generator_for_report
      "#{generator.drilldown_name(question: question_id, table: table_id, cell: cell_id)} Cell Detail"
    end

    private

    def builder
      # Subclasses must implement - should return a memoized builder instance
      raise NotImplementedError
    end

    def question_id
      params['measure_id'].presence || params['question']
    end

    def table_id
      params.fetch('table')
    end

    def cell_id
      params.fetch('cell_id')
    end

    def report
      @report ||= ::HudReports::ReportInstance.find(params.fetch('report_id'))
    end
  end
end
