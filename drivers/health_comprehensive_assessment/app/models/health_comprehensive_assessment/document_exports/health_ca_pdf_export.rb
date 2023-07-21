###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
        title: _('Comprehensive Assessment'),
        pdf: true,
      }
    end

    def perform
      with_status_progression do
        template_file = 'health_comprehensive_assessment/assessments/edit_pdf'
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
          template: 'health_comprehensive_assessment/assessments/pdf_header',
          layout: false,
          user: user,
          assigns: view_assigns,
        )
        footer_html = PdfGenerator.html(
          controller: controller_class,
          template: 'health_comprehensive_assessment/assessments/pdf_footer',
          layout: false,
          user: user,
          assigns: view_assigns,
        )
        PdfGenerator.new.perform(
          html: html,
          file_name: "#{_('Comprehensive Assessment')} #{DateTime.current.to_s(:db)}",
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

    private def controller_class
      HealthComprehensiveAssessment::AssessmentsController
    end
  end
end
