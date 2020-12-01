###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
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
        PdfGenerator.new.perform(
          html: view.render(file: template_file, layout: 'layouts/healthcare_report'),
          file_name: "Housing Status Changes #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    def download_title
      "Housing Status Changes Report"
    end

    protected def report_class
      WarehouseReport::Health::HousingStatusChanges
    end

    protected def view
      context = WarehouseReports::Health::HousingStatusChangesController.view_paths
      view = HousingStatusChangesExportTemplate.new(context, view_assigns)
      view.current_user = user
      view
    end

    class HousingStatusChangesExportTemplate < ActionView::Base
      include ActionDispatch::Routing::PolymorphicRoutes
      include Rails.application.routes.url_helpers
      include ApplicationHelper
      attr_accessor :current_user
      def show_client_details?
        false
      end
    end
  end
end
