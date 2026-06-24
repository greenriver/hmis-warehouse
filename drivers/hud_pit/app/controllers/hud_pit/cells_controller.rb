###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudPit
  class CellsController < ::HudReports::BaseController
    include PitConcern
    before_action :set_report
    before_action :set_question
    before_action :enforce_hiv_drilldown_access

    def report_param_name
      :pit_id
    end

    private def set_question
      @question = generator.valid_question_number(params[:question] || params[:question_id])
    end

    def show
      @cell = @report.valid_cell_name(params[:id])
      @table = generator.valid_table_name(params[:table])
      @clients = HudPit::Fy2022::PitClient.
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id))
      @name = "#{generator.file_prefix} #{@question} #{@cell}"
      respond_to do |format|
        format.html {}
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=#{@name}.xlsx"
        end
      end
    end

    # No-op when the user may view HIV drilldowns, or when this cell is not the
    # HIV/AIDS row for a question that defines HIV_AIDS_ROW. Otherwise redirects
    # with an alert (before_action halts the request).
    private def enforce_hiv_drilldown_access
      return if current_user.can_view_hiv_status?

      question_class = generator.questions[@question]
      return unless question_class&.const_defined?(:HIV_AIDS_ROW)

      row_number = row_number_from_cell_label(params[:id])
      return unless row_number == question_class::HIV_AIDS_ROW

      redirect_to(
        result_hud_reports_pit_question_path(pit_id: @report.id, id: @question),
        alert: 'You do not have permission to view HIV/AIDS drilldown data.',
      )
    end

    # Cell drilldown `params[:id]` matches HUD report table links from
    # app/views/hud_reports/_table.haml: "#{column_letter}#{row_num}" (e.g. "B4", "A12").
    private def row_number_from_cell_label(cell_label)
      cell_label.to_s.scan(/\d+/).first.to_i
    end
  end
end
