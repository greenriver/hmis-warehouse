###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PriorLivingSituation::DocumentExports
  class PriorLivingSituationExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_view_any_reports? && report_class.viewable_by(user)
    end

    protected def report
      @report ||= report_class.find(params['id'])
    end

    protected def view_assigns
      {
        report: report,
        filter: filter,
        pdf: true,
      }
    end

    protected def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new(user_id: user.id)
        filter_params = params['filters'].presence&.deep_symbolize_keys
        f.set_from_params(filter_params) if filter_params

        f
      end
    end

    protected def params
      query_string.present? ? Rack::Utils.parse_nested_query(query_string) : {}
    end

    def perform
      with_status_progression do
        template_file = 'prior_living_situation/warehouse_reports/prior_living_situation/index_pdf'
        PdfGenerator.new.perform(
          html: view.render(file: template_file, layout: 'layouts/performance_report'),
          file_name: "Prior Living Situation #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected def report_class
      PriorLivingSituation::PriorLivingSituationReport
    end

    protected def view
      context = PriorLivingSituation::WarehouseReports::PriorLivingSituationController.view_paths
      view = PriorLivingSituationExportTemplate.new(context, view_assigns)
      view.current_user = user
      view
    end

    class PriorLivingSituationExportTemplate < ActionView::Base
      include ActionDispatch::Routing::PolymorphicRoutes
      include Rails.application.routes.url_helpers
      include ApplicationHelper
      attr_accessor :current_user
      def show_client_details?
        @show_client_details ||= current_user.can_view_clients?
      end
    end
  end
end
