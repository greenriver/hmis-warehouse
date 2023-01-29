###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonReports::DocumentExports
  class StreetToHomePdfExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_view_any_reports? && report_class.viewable_by(user)
    end

    protected def report
      @report ||= report_class.new(filter)
    end

    protected def view_assigns
      comparison_filter = filter.to_comparison
      comparison_report = report_class.new(comparison_filter) if report.include_comparison?

      {
        report: report,
        filter: filter,
        comparison: comparison_report || report,
        comparison_filter: comparison_filter,
        pdf: true,
      }
    end

    def perform
      with_status_progression do
        template_file = 'boston_reports/warehouse_reports/street_to_home/index_pdf'
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
          file_name: "Street To Home #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected def report_class
      BostonReports::StreetToHome
    end

    private def controller_class
      BostonReports::WarehouseReports::StreetToHomesController
    end
  end
end
