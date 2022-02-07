###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class BackgroundRender::CoreDemographicsReportJob < BackgroundRenderJob

  def render_html(partial:, filters:, user_id:)
    current_user = User.find(user_id)
    @filter = ::Filters::FilterBase.new(user_id: user_id).set_from_params(JSON.parse(filters).with_indifferent_access)
    @comparison_filter = @filter.to_comparison
    set_report
    @section = @report.class.available_section_types.detect do |m|
      m == partial
    end
    @section = 'overall' if @section.blank? && params.require(:partial) == 'overall'

    raise 'Rollup not in allowlist' unless @section.present?

    @section = @report.section_subpath + @section
    CoreDemographicsReport::WarehouseReports::CoreController.render(
      partial: @section,
      assigns: {
        report: @report,
        section: @section,
        comparison: @comparison,
        comparison_filter: @comparison_filter,
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
    CoreDemographicsReport::Core
  end
end
