###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  module DocumentExports
    class CellDetailExport < ::GrdaWarehouse::DocumentExport
      def authorized?
        report.user_id == user_id && user.can_view_any_reports?
      end

      def perform
        with_status_progression do
          result = HudApr::CellDetailExportBuilder.new(
            user: user,
            report: report,
            question: params.fetch('question'),
            cell_id: params.fetch('cell_id'),
            table: params.fetch('table'),
            report_type: params.fetch('report_type'),
          ).call

          self.filename = result.filename
          self.file_data = result.data
          self.mime_type = DocumentExportBehavior::EXCEL_MIME_TYPE
        end
      end

      def download_title
        "#{params.fetch('report_type').upcase} Cell Detail - #{report.id} - #{params.fetch('question')} - Table #{params.fetch('table')} - Cell #{params.fetch('cell_id')}"
      end

      private

      def report
        @report ||= ::HudReports::ReportInstance.find(params.fetch('report_id'))
      end
    end
  end
end
