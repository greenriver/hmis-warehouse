###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class BackgroundRender::AnalysisToolJob < BackgroundRenderJob
  def render_html(filters:, user_id:, row_breakdown:, col_breakdown:)
    current_user = User.find(user_id)
    @filter = ::Filters::FilterBase.new(user_id: user_id).set_from_params(JSON.parse(filters).with_indifferent_access)
    set_report
    @section = 'table'
    @section = @report.section_subpath + @section
    @report.breakdowns = {
      row: row_breakdown,
      col: col_breakdown,
    }
    AnalysisTool::WarehouseReports::AnalysisToolController.render(
      partial: @section,
      assigns: {
        report: @report,
        section: @section,
        filter: @filter,
      },
      locals: {
        current_user: current_user,
      },
    )
  end

  private def set_report
    @report = report_class.new(@filter)
    if @report.include_comparison?
      @comparison = report_class.new(@comparison_filter)
    else
      @comparison = @report
    end
  end

  private def report_class
    AnalysisTool::Report
  end
end
