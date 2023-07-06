###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DocumentExports
  class HealthPctpPdfExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      # TODO
      true
    end

    protected def careplan
      patient = Health::Patient.viewable_by_user(user).find_by(client_id: params['client_id'].to_i)
      @careplan ||= patient.pctps.find(params['id'])
    end

    protected def view_assigns
      {
        careplan: careplan,
        user: user,
        title: _('Care Plan / Patient-Centered Treatment Plan'),
        pdf: true,
      }
    end

    def perform
      with_status_progression do
        template_file = 'health_pctp/careplans/edit_pdf'
        layout = 'layouts/performance_report'
        # https://stackoverflow.com/questions/55865582/set-dynamic-header-and-footer-data-on-pdf-generation-from-rails-grover-gem

        html = PdfGenerator.html(
          controller: controller_class,
          template: template_file,
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        PdfGenerator.new.perform(
          html: html,
          file_name: "#{_('Care Plan / Patient-Centered Treatment Plan')} #{DateTime.current.to_s(:db)}",
          options: {
            print_background: true,
            display_header_footer: true,
            header_template: '',
            footer_template: '',
            margin: {
              bottom: '.75in',
            },
          },
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    # protected def report_class
    #   HmisDataQualityTool::Report
    # end

    private def controller_class
      # HmisDataQualityTool::WarehouseReports::ReportsController
      HealthPctp::CareplansController
    end
  end
end
