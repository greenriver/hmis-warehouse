###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HealthComprehensiveAssessment::DocumentExports
  class CaAssessmentPdfExport
    def self.generate(user:, assessment:)
      new(
        user: user,
        assessment: assessment,
      ).generate
    end

    def initialize(user:, assessment:)
      @user = user
      @assessment = assessment
    end

    def generate
      layout = 'layouts/careplan_pdf'

      first_page_html = PdfGenerator.html(
        controller: controller_class,
        template: 'health_comprehensive_assessment/assessments/pdf_first_page',
        layout: layout,
        user: @user,
        assigns: view_assigns,
      )
      html = PdfGenerator.html(
        controller: controller_class,
        template: 'health_comprehensive_assessment/assessments/edit_pdf',
        layout: layout,
        user: @user,
        assigns: view_assigns,
      )
      first_page_header_html = PdfGenerator.html(
        controller: controller_class,
        partial: 'health_comprehensive_assessment/assessments/pdf_first_page_header',
        user: @user,
        assigns: view_assigns,
      )
      header_html = PdfGenerator.html(
        controller: controller_class,
        partial: 'health_comprehensive_assessment/assessments/pdf_header',
        user: @user,
        assigns: view_assigns,
      )
      footer_html = PdfGenerator.html(
        controller: controller_class,
        partial: 'health_comprehensive_assessment/assessments/pdf_footer',
        user: @user,
        assigns: view_assigns,
      )

      base_options = {
        print_background: true,
        prefer_css_page_size: true,
        scale: 1,
        format: 'tabloid',
      }

      first_page_options = base_options.merge(
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

      body_options = base_options.merge(
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

      first_page_pdf = PdfGenerator.render_pdf(first_page_html, options: first_page_options)
      body_pdf = PdfGenerator.render_pdf(html, options: body_options)

      PdfGenerator.merge_inline_pdfs([first_page_pdf, body_pdf])
    end

    private

    def view_assigns
      {
        assessment: @assessment,
        user: @user,
        title: 'Comprehensive Assessment',
        pdf: true,
      }
    end

    def controller_class
      HealthComprehensiveAssessment::AssessmentsController
    end
  end
end
