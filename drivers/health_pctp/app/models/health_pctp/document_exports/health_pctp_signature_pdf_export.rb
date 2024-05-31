###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPctp::DocumentExports
  class HealthPctpSignaturePdfExport < ::Health::DocumentExport
    include ApplicationHelper
    def authorized?
      # TODO
      true
    end

    def regenerate?
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
        title: Translation.translate('Care Plan / Patient-Centered Treatment Plan'),
        pdf: true,
      }
    end

    def perform
      with_status_progression do
        template_file = 'health_pctp/careplans/signature_pdf'
        layout = 'layouts/careplan_pdf'
        # https://stackoverflow.com/questions/55865582/set-dynamic-header-and-footer-data-on-pdf-generation-from-rails-grover-gem

        html = PdfGenerator.html(
          controller: controller_class,
          template: template_file,
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        header_html = PdfGenerator.html(
          controller: controller_class,
          partial: 'health_pctp/careplans/pdf_header',
          user: user,
          assigns: view_assigns,
        )
        footer_html = PdfGenerator.html(
          controller: controller_class,
          partial: 'health_pctp/careplans/pdf_footer',
          user: user,
          assigns: view_assigns,
        )
        PdfGenerator.new.perform(
          html: html,
          file_name: "#{Translation.translate('Care Plan / Patient-Centered Treatment Plan')} #{DateTime.current.to_fs(:db)}",
          options: {
            print_background: true,
            display_header_footer: true,
            header_template: header_html,
            footer_template: footer_html,
            prefer_css_page_size: true,
            scale: 1,
            margin: {
              top: '0.8in',
              bottom: '1.2in',
              left: '.4in',
              right: '.4in',
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
