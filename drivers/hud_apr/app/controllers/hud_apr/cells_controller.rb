###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

    # TODO: this covers many of the possible formatting needs, but not all
    # Also, this _should_ be fairly portable for all HUD reports, so it might be worth centralizing it eventually
    def formatted_cell(cell, key, user)
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
      when /.*length_of_stay$/
        HudUtility2024.residence_prior_length_of_stay(cell)
      when /^ssn$/
        if user.can_view_full_ssn?
          cell
        else
          masked_ssn(cell)
        end
      when /^dob$/
        if user.can_view_full_dob?
          cell
        else
          '[REDACTED]'
        end
      when /ssn_quality$/
        HudUtility2024.ssn_data_quality(cell)
      when /name_quality$/
        HudUtility2024.name_data_quality(cell)
      when /dob_quality$/
        HudUtility2024.dob_data_quality(cell)
      when /veteran_status$/
        HudUtility2024.veteran_status(cell)
      when /relationship_to_hoh$/
        HudUtility2024.relationship_to_hoh(cell)
      when /.*disabling_condition$/
        HudUtility2024.disability_response(cell)
      else
        cell
      end
    end
    helper_method :formatted_cell
  end
end
