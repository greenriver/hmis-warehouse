###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudDataQualityReport
  class LegacyResultsController < ApplicationControllerV2
    authorize_with { current_user.can_view_hud_reports? }

    def show
      @report = Report.find(params[:legacy_dq_id].to_i)
      # viewable_by narrows to the user's own results unless they can view all HUD
      # reports; going through @report also keeps a mismatched id pair from resolving.
      @result = @report.report_results.viewable_by(current_user).find(params[:id].to_i)
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
