###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  class CellsController < HudApr::QuestionsController
    include ApplicationHelper
    include ActionView::Helpers::TagHelper
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
      @name = "#{generator.file_prefix} #{@question} #{@table} #{@cell}"
      respond_to do |format|
        format.html {}
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=#{@name}.xlsx"
        end
      end
    end
  end
end
