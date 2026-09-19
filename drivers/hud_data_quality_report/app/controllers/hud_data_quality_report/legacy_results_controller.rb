###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudDataQualityReport
  class LegacyResultsController < ApplicationControllerV2
    authorize_with { GrdaWarehouse::WarehouseReports::ReportDefinition.url_viewable_by?('hud_reports/dqs', current_user) }

    def show
      @report = Report.find(params[:legacy_dq_id].to_i)
      # Going through @report keeps a mismatched id pair from resolving.
      @result = @report.report_results.runs_visible_to(current_user).find(params[:id].to_i)
      respond_to do |format|
        format.html {} # render the default template
        format.csv do
          unless @result.results.present?
            flash[:alert] = "There are no results to show for #{@report.name}"
            redirect_to action: :show
          end
          response.headers['Content-Type'] = 'text/csv'
          response.headers['Content-Disposition'] = "attachment; filename=\"#{@report.name}-#{@result.created_at.strftime('%Y-%m-%dT%H%M ')}.csv\""
        end
      end
    end
  end
end
