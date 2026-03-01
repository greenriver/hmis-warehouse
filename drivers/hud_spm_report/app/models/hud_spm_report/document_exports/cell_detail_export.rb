# frozen_string_literal: true

module HudSpmReport
  module DocumentExports
    class CellDetailExport < ::HudReports::CellDetailExportBase
      private

      def builder
        @builder ||= HudSpmReport::CellDetailExportBuilder.new(
          user: user,
          report: report,
          measure_id: question_id,
          cell_id: cell_id,
          table: table_id,
        )
      end
    end
  end
end
