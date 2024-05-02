###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthComprehensiveAssessment::DocumentExports
  class HealthCaPdfExport < ::Health::DocumentExport
    include ApplicationHelper
    def authorized?
      # TODO
      true
    end

    def regenerate?
      true
    end

    protected def comprehensive_assessment
      patient = Health::Patient.viewable_by_user(user).find_by(client_id: params['client_id'].to_i)
      @comprehensive_assessment ||= patient.comprehensive_assessments.find(params['id'])
    end

    protected def view_assigns
      {
        assessment: comprehensive_assessment,
        user: user,
        title: Translation.translate('Comprehensive Assessment'),
        pdf: true,
      }
    end

    def perform
      with_status_progression do
        layout = 'layouts/careplan_pdf'
        # https://stackoverflow.com/questions/55865582/set-dynamic-header-and-footer-data-on-pdf-generation-from-rails-grover-gem

        first_page_html = PdfGenerator.html(
          controller: controller_class,
          template: 'health_comprehensive_assessment/assessments/pdf_first_page',
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        html = PdfGenerator.html(
          controller: controller_class,
          template: 'health_comprehensive_assessment/assessments/edit_pdf',
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        first_page_header_html = PdfGenerator.html(
          controller: controller_class,
          partial: 'health_comprehensive_assessment/assessments/pdf_first_page_header',
          user: user,
          assigns: view_assigns,
        )
        header_html = PdfGenerator.html(
          controller: controller_class,
          partial: 'health_comprehensive_assessment/assessments/pdf_header',
          user: user,
          assigns: view_assigns,
        )
        footer_html = PdfGenerator.html(
          controller: controller_class,
          partial: 'health_comprehensive_assessment/assessments/pdf_footer',
          user: user,
          assigns: view_assigns,
        )

        options_no_header = {
          print_background: true,
          prefer_css_page_size: true,
          scale: 1,
        }

        first_page_options = options_no_header.merge(
          display_header_footer: true,
          header_template: first_page_header_html,
          footer_template: "<html><head><meta charset='UTF-8' /></head><body></body></html>",
          margin: {
            top: '0.8in',
            bottom: '.4in',
            left: '.4in',
            right: '.4in',
          },
        )

        body_options = options_no_header.merge(
          display_header_footer: true,
          header_template: header_html,
          footer_template: footer_html,
          margin: {
            top: '0.8in',
            bottom: '1.2in',
            left: '.4in',
            right: '.4in',
          },
        )

        pdf = CombinePDF.new
        pdf << CombinePDF.parse(PdfGenerator.new.render_pdf(first_page_html, options: first_page_options), allow_optional_content: true)
        pdf << CombinePDF.parse(PdfGenerator.new.render_pdf(html, options: body_options), allow_optional_content: true)

        file_name = "#{Translation.translate('Comprehensive Assessment')} #{DateTime.current.to_fs(:db)}"
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
      HealthComprehensiveAssessment::AssessmentsController
    end

    protected def report_class
      HealthComprehensiveAssessment::Assessment
    end
  end
end
