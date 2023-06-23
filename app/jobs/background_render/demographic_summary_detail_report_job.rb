###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class BackgroundRender::DemographicSummaryDetailReportJob < BackgroundRenderJob
  def render_html(filters:, user_id:, key:)
    current_user = User.find(user_id)
    @filter = ::Filters::FilterBase.new(user_id: user_id).set_from_params(JSON.parse(filters).with_indifferent_access)
    @comparison_filter = @filter.to_comparison
    @key = key
    set_report

    html = CoreDemographicsReport::WarehouseReports::DemographicSummaryController.render(
      partial: 'details',
      assigns: {
        report: @report,
        comparison: @comparison,
        comparison_filter: @comparison_filter,
        filter: @filter,
        key: @key,
      },
      locals: {
        current_user: current_user,
      },
    )
    puts html if Rails.env.development?
    html
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
    CoreDemographicsReport::DemographicSummary::Report
  end
end
