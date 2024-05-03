###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPctp::DocumentExports
  class HealthPctpPdfExport < ::Health::DocumentExport
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
        layout = 'layouts/careplan_pdf'
        # https://stackoverflow.com/questions/55865582/set-dynamic-header-and-footer-data-on-pdf-generation-from-rails-grover-gem

        coverpage_html = PdfGenerator.html(
          controller: controller_class,
          template: 'health_pctp/careplans/pdf_coverpage',
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        html = PdfGenerator.html(
          controller: controller_class,
          template: 'health_pctp/careplans/edit_pdf',
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

        options_no_header = {
          print_background: true,
          prefer_css_page_size: true,
          scale: 1,
          margin: {
            top: '0.8in',
            bottom: '1.2in',
            left: '.4in',
            right: '.4in',
          },
        }

        options = options_no_header.merge(
          display_header_footer: true,
          header_template: header_html,
          footer_template: footer_html,
        )

        pdf = CombinePDF.new
        pdf << CombinePDF.parse(PdfGenerator.new.render_pdf(coverpage_html, options: options_no_header), allow_optional_content: true)
        pdf << CombinePDF.parse(PdfGenerator.new.render_pdf(html, options: options), allow_optional_content: true)
        pdf << CombinePDF.parse(careplan.health_file.content, allow_optional_content: true) if careplan.health_file.present?

        file_name = "#{Translation.translate('Care Plan / Patient-Centered Treatment Plan')} #{DateTime.current.to_fs(:db)}"
        PdfGenerator.new.perform(
          html: '',
          file_name: file_name,
          pdf_data: pdf.to_pdf,
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    private def controller_class
      HealthPctp::CareplansController
    end

    protected def report_class
      HealthPctp::Careplan
    end
  end
end
