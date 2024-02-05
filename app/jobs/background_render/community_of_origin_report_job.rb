###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class BackgroundRender::CommunityOfOriginReportJob < BackgroundRenderJob
  def render_html(partial:, filters:, user_id:)
    current_user = User.find(user_id)
    @filter = ::Filters::FilterBase.new(user_id: user_id).set_from_params(JSON.parse(filters).with_indifferent_access)
    set_report
    @section = @report.class.allowable_section_types.detect do |m|
      m == partial
    end
    @section = 'across_the_country' if @section.blank? && params.require(:partial) == 'across_the_country'

    raise 'Rollup not in allowlist' unless @section.present?

    @section = @report.section_subpath + @section
    BostonReports::WarehouseReports::CommunityOfOriginsController.render(
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
  end

  private def report_class
    BostonReports::CommunityOfOrigin
  end
end
