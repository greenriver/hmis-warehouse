###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  module DocumentExports
    class CellDetailExport < ::HudReports::CellDetailExportBase
      private

      def builder_class
        HudApr::CellDetailExportBuilder
      end

      def builder_params
        {
          user: user,
          report: report,
          question: question_id,
          cell_id: cell_id,
          table: table_id,
          report_type: params.fetch('report_type'),
        }
      end

      def report_type_display
        params.fetch('report_type').upcase
      end
    end
  end
end
