###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr
  class CellsController < HudApr::QuestionsController
    private def set_question
      @question = generator.valid_question_number(params[:question] || params[:question_id])
    end

    def show
      @cell = @report.valid_cell_name(params[:id])
      @table = @report.valid_table_name(params[:table])
      @clients = HudApr::Fy2020::AprClient.
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id))
      @name = "#{report_short_name} #{@question} #{@cell}"
      respond_to do |format|
        format.html {}
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=#{@name}.xlsx"
        end
      end
    end

    def formatted_cell(cell)
      return cell.to_json if cell.is_a?(Array) || cell.is_a?(Hash)

      cell
    end
    helper_method :formatted_cell
  end
end
