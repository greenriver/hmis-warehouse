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

      def builder
        @builder ||= HudApr::CellDetailExportBuilder.new(
          user: user,
          report: report,
          measure_id: question_id,
          cell_id: cell_id,
          table: table_id,
          report_type: params.fetch('report_type'),
        )
      end
    end
  end
end
