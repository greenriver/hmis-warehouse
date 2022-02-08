###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::DocumentExports
  class HousingStatusChangesExport < ::Health::DocumentExport
    def authorized?
      user.can_view_aggregate_health?
    end

    protected def report
      report_params = params.with_indifferent_access || {}
      end_date = (report_params[:end_date] || Date.current).to_date
      start_date = (report_params[:start_date] || end_date - 1.year).to_date
      acos = report_params[:aco]&.select { |id| id.present? }
      @report ||= report_class.new(start_date, end_date, acos, user: user)
    end

    protected def view_assigns
      {
        report: report,
        pdf: true,
      }
    end

    def params
      query_string.present? ? Rack::Utils.parse_nested_query(query_string) : {}
    end

    def perform
      with_status_progression do
        template_file = 'warehouse_reports/health/housing_status_changes/index_pdf'
        layout = 'layouts/healthcare_report'

        html = PdfGenerator.html(
          controller: controller_class,
          template: template_file,
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        PdfGenerator.new.perform(
          html: html,
          file_name: "Housing Status Changes #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    def download_title
      'Housing Status Changes Report'
    end

    protected def report_class
      WarehouseReport::Health::HousingStatusChanges
    end

    private def controller_class
      WarehouseReports::Health::HousingStatusChangesController
    end
  end
end
