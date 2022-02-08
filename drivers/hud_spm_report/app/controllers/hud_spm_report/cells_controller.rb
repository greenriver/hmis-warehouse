###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

      # this is a very wide table. just grab the cols related to this measure
      q_num = @question[/\d+\z/]
      cols = ['client_id', 'first_name', 'last_name'] + HudSpmReport::Fy2020::SpmClient.column_names.select { |c| c.starts_with? "m#{q_num}" }
      @headers = cols.map do |col|
        [col, HudSpmReport::Fy2020::SpmClient.human_attribute_name(col)]
      end.to_h

      @clients = HudSpmReport::Fy2020::SpmClient.
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id))

      respond_to do |format|
        format.html {}
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=#{@name}.xlsx"
        end
      end
    end

    def formatted_cell(cell)
      return view_context.content_tag(:pre, JSON.pretty_generate(cell)) if cell.is_a?(Array) || cell.is_a?(Hash)

      cell
    end
    helper_method :formatted_cell
  end
end
