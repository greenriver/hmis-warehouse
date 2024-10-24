###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport
  class CellsController < HudSpmReport::BaseController
    private def report_param_name
      :spm_id
    end

    def show
      params.require(report_param_name)

      set_report

      @question = generator.valid_question_number params.require(:measure_id)
      @cell = @report.valid_cell_name params.require(:id)
      @table = params.require(:table) # valid_table_name is too strict for the SPM table names
      @name = "#{generator.file_prefix} #{@question} #{@cell}"

      @headers = generator.column_headings(@question)

      @clients = generator.client_class(@question).
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id))

      respond_to do |format|
        format.html {}
        format.xlsx do
          @headers = @headers.transform_keys(&:to_s).except(*generator.pii_columns) unless GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
          headers['Content-Disposition'] = "attachment; filename=#{@name}.xlsx"
        end
      end
    end

    def formatted_cell(cell, key)
      return view_context.content_tag(:pre, JSON.pretty_generate(cell)) if cell.is_a?(Array) || cell.is_a?(Hash)
      return view_context.yes_no(cell) if cell.in?([true, false])

      case key.to_s
      when /project_type$/
        HudUtility2024.project_type_brief(cell)
      when /prior_living_situation$/
        HudUtility2024.living_situation(cell)
      when /.*destination$/
        HudUtility2024.destination(cell)
      when /_days_/
        number_with_delimiter(cell)
      else
        cell
      end
    end
    helper_method :formatted_cell
  end
end
