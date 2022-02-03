###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard::DocumentExports
  class ScorecardExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      # TODO: What are the access rules?
      true
    end

    protected def report
      @report ||= report_class.find(params['report_id'].to_i)
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
        template_file = 'project_scorecard/warehouse_reports/scorecards/show_pdf'
        layout = 'layouts/performance_report'

        html = PdfGenerator.html(
          controller: controller_class,
          template: template_file,
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        PdfGenerator.new.perform(
          html: html,
          file_name: "#{@report.project.name.titlecase} Scorecard #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    def pdf_data
      {
        type: type,
        query_string: query_string,
      }
    end

    protected def report_class
      ProjectScorecard::Report
    end

    private def controller_class
      ProjectScorecard::WarehouseReports::ScorecardsController
    end
  end
end
