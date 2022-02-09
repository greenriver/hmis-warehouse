###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::DocumentExports
  class HouseholdPerformanceExport < BasePerformanceExport
    def perform
      with_status_progression do
        template_file = 'performance_dashboards/overview/index_pdf'
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
          file_name: "Household Performance #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    def download_title
      'Household Performance Report'
    end

    protected def report_class
      PerformanceDashboards::Household
    end

    private def controller_class
      PerformanceDashboards::HouseholdController
    end
  end
end
