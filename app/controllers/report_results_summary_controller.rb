###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class ReportResultsSummaryController < ApplicationController
  before_action :require_can_view_all_reports!
  before_action :set_report_results_summary, :set_report_results, only: [:show]

  def show
    @all_results = @results.map(&:results).reduce({}, :merge).deep_symbolize_keys!
    respond_to do |format|
      format.html {} # render the default template
      format.csv do
        unless @results.present?
          flash[:alert] = "There are no results to show for #{@report_results_summary.name}"
          redirect_to action: :show
        end
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=\"#{@report_results_summary.name}-#{Time.now}.csv\""
      end
    end
  end

  private

  def report_results_summary_source
    ReportResultsSummary
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_report_results
    most_recent_results = @report_results_summary.report_results.most_recent
    @results = most_recent_results.map { |t, d| ReportResult.where(report_id: Report.where(type: t).first, updated_at: d).first }
    @options = @report_results_summary.report_results.first&.options
  end

  def set_report_results_summary
    @report_results_summary = report_results_summary_source.find(params[:id].to_i)
  end
end
