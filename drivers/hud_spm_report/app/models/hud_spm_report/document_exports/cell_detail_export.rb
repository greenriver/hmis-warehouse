# frozen_string_literal: true

module HudSpmReport
  module DocumentExports
    class CellDetailExport < ::HudReports::CellDetailExportBase
      private

      def generator_class
        @generator_class ||= HudSpmReport::CellDetailExportBuilder.new(builder_params).generator_for_report
      end

      def builder_class
        HudSpmReport::CellDetailExportBuilder
      end

      def builder_params
        {
          user: user,
          report: report,
          measure_id: question_id,
          cell_id: cell_id,
          table: table_id,
        }
      end
    end
  end
end
