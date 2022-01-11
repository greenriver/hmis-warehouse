###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::DocumentExports
  class BedUtilizationExport < ::GrdaWarehouse::DocumentExport
    def authorized?
      user.can_view_any_reports? && report_class.viewable_by(user)
    end

    def perform
      with_status_progression do
        template_file = 'warehouse_reports/bed_utilization/index_pdf'
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
          file_name: "Bed Utilization #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    def download_title
      'Bed Utilization Report'
    end

    protected def report_class
      WarehouseReport::BedUtilization
    end

    private def controller_class
      ::WarehouseReports::BedUtilizationController
    end

    protected def report
      @report ||= report_class.new(filter: filter)
    end

    protected def view_assigns
      {
        report: report,
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
  end
end
