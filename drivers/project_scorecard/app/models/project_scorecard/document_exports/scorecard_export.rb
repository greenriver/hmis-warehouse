###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
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
        PdfGenerator.new.perform(
          html: view.render(file: template_file, layout: 'layouts/performance_report'),
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

    protected def view
      context = ProjectScorecard::WarehouseReports::ScorecardsController.view_paths
      view = ScorecardExportTemplate.new(context, view_assigns)
      view.current_user = user
      view
    end

    class ScorecardExportTemplate < ActionView::Base
      include ActionDispatch::Routing::PolymorphicRoutes
      include Rails.application.routes.url_helpers
      include ApplicationHelper
      attr_accessor :current_user

      def show_client_details?
        false
      end

      def protect_against_forgery?
        false
      end
    end
  end
end
