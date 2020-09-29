###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr
  class CellsController < HudApr::QuestionsController
    private def set_question
      @question = generator.valid_question_number(params[:question] || params[:question_id])
    end

    def show
      @cell = @report.valid_cell_name(params[:id])
      @table = @report.valid_table_name(params[:table])
      report_cell = @report.report_cells.for_table(@table).for_cell(@cell).first
      @clients = report_cell.universe_members
    end
  end
end
