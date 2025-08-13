###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudDataQualityReport
  class CellsController < HudDataQualityReport::QuestionsController
    include ::HudReports::ArtifactAwareCells

    before_action :set_report
    before_action :set_question

    def show
      @cell = @report.valid_cell_name(params[:id])
      @table = @report.valid_table_name(params[:table])
      @clients = load_cell_clients(HudDataQualityReport::Fy2020::DqClient, @cell, @table)
      @name = "#{report_short_name} #{@question} #{@cell}"
      respond_to do |format|
        format.html {}
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=#{@name}.xlsx"
        end
      end
    end
  end
end
