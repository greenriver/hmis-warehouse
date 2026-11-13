###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module BostonProjectScorecard::DocumentExports
  class ScorecardExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_view_any_reports? &&
        GrdaWarehouse::WarehouseReports::ReportDefinition.url_viewable_by?('boston_project_scorecard/warehouse_reports/scorecards', user) &&
        report.present?
    end

    protected def report
      @report ||= report_class.viewable_by(user).find_by(id: params['report_id'].to_i)
    end

    protected def view_assigns
      {
        report: report,
        pdf: true,
      }
    end

    protected def params
      query_string.present? ? Rack::Utils.parse_nested_query(query_string) : {}
    end

    def perform
      with_status_progression do
        template_file = 'boston_project_scorecard/warehouse_reports/scorecards/show_pdf'
        layout = 'layouts/performance_report'

        html = PdfGenerator.html(
          controller: controller_class,
          template: template_file,
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        file_name = @report.project&.name(user) || @report.project_group&.name
        PdfGenerator.new.perform(
          html: html,
          file_name: "#{file_name.titlecase} Scorecard #{DateTime.current.to_fs(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    def pdf_data
      # DocumentExport uses the query string to determine if it has already generated the PDF for a document
      # Include a hash of the report to detect edits
      hash = Digest::MD5.hexdigest(report.to_json)
      {
        type: type,
        query_string: query_string + "&hash=#{hash}",
      }
    end

    protected def report_class
      BostonProjectScorecard::Report
    end

    private def controller_class
      BostonProjectScorecard::WarehouseReports::ScorecardsController
    end
  end
end
