###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper
  class CellsController < HopwaCaper::QuestionsController
    before_action :set_report
    before_action :set_question

    def show
      @cell = @report.valid_cell_name(params[:id])
      @table = @report.valid_table_name(params[:table])
      @enrollments = HopwaCaper::Enrollment.
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(@table).for_cell(@cell)).
        merge(::HudReports::ReportInstance.where(id: @report.id))
      @services = HopwaCaper::Service.
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

    def formatted_cell(cell)
      return cell.to_json if cell.is_a?(Array) || cell.is_a?(Hash)

      cell
    end
    helper_method :formatted_cell

    def count_dates(date_array)
      date_array.sort.tally.map { |k, v| "#{k} (#{v})" }.join(', ')
    end
    helper_method :count_dates
  end
end
