# frozen_string_literal: true

module HudSpmReport
  module DocumentExports
    class CellDetailExport < ::GrdaWarehouse::DocumentExport
      def authorized?
        user.can_view_any_reports?
      end

      def perform
        with_status_progression do
          result = HudSpmReport::CellDetailExportBuilder.new(
            user: user,
            report: report,
            measure_id: params.fetch('measure_id'),
            cell_id: params.fetch('cell_id'),
            table: params.fetch('table'),
          ).call

          self.filename = result.filename
          self.file_data = result.data
          self.mime_type = DocumentExportBehavior::EXCEL_MIME_TYPE
        end
      end

      def download_title
        "SPM Cell Detail - #{report.id} - #{params.fetch('measure_id')} - Table #{params.fetch('table')} - Cell #{params.fetch('cell_id')}"
      end

      private

      def report
        @report ||= ::HudReports::ReportInstance.find(params.fetch('report_id'))
      end
    end
  end
end
