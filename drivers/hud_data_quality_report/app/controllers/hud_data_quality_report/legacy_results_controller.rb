###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport
  class LegacyResultsController < ApplicationController
    def show
      @report = Report.find(params[:legacy_dq_id].to_i)
      @result = ReportResult.find(params[:id].to_i)
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
