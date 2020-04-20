###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# A HUD Report instance, identified by report name (e.g., report_name: 'CE APR - 2020')
module HudReports
  class ReportInstance < GrdaWarehouseBase
    self.table_name = 'hud_report_instances'

    belongs_to :user
    has_many :report_cells

    # An answer cell in a question
    #
    # @param question [String] the question name (e.g., 'Q1')
    # @param cell [String] the cell name (e.g, 'B2')
    # @return [ReportCell] the answer cell
    def answer(question:, cell: nil)
      report_cells.
        where(question: question, cell_name: cell, universe: false).
        first_or_create
    end

    # The universe of clients for a question
    #
    # @param question [String] the question name (e.g., 'Q1')
    # @return [ReportCell] the universe cell
    def universe(question)
      report_cells.
        where(question: question, universe: true).
        first_or_create
    end
  end
end