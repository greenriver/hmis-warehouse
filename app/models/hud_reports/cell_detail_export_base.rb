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
  # - builder_class: The ExportBuilder class to use
  # - builder_params: Hash of parameters for the builder
  #
  # Subclasses can optionally override:
  # - report_type_display: Short acronym for the report (e.g., 'SPM', 'APR')
  class CellDetailExportBase < ::GrdaWarehouse::DocumentExport
    def authorized?
      (report.user_id == user_id || user.can_view_all_hud_reports?) && user.can_view_any_reports?
    end

    def perform
      with_status_progression do
        result = builder_class.new(builder_params).call

        self.filename = result.filename
        self.file_data = result.data
        self.mime_type = DocumentExportBehavior::EXCEL_MIME_TYPE
      end
    end

    def download_title
      "#{report.drilldown_name(question: question_id, table: table_id, cell: cell_id, prefix: report_prefix)} Cell Detail"
    end

    private

    def report_prefix
      "#{report_type_display} #{report_fiscal_year}"
    end

    def report_fiscal_year
      report.report_name.match(/FY \d{4}/).to_s
    end

    def builder_class
      # Subclasses must implement
      raise NotImplementedError
    end

    def builder_params
      # Subclasses must implement
      raise NotImplementedError
    end

    def report_type_display
      'SPM'
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
