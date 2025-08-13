###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudPit
  class CellsController < ::HudReports::BaseController
    include PitConcern
    include ::HudReports::ArtifactAwareCells

    before_action :set_report
    before_action :set_question

    def report_param_name
      :pit_id
    end

    private def set_question
      @question = generator.valid_question_number(params[:question] || params[:question_id])
    end

    def show
      @cell = @report.valid_cell_name(params[:id])
      @table = generator.valid_table_name(params[:table])
      @clients = load_cell_clients(HudPit::Fy2022::PitClient, @cell, @table)
      @name = "#{generator.file_prefix} #{@question} #{@cell}"
      respond_to do |format|
        format.html {}
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=#{@name}.xlsx"
        end
      end
    end
  end
end
