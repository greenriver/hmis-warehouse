###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HealthThriveAssessment::DocumentExports
  class ThriveAssessmentPdfExport
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
      body_html = PdfGenerator.html(
        controller: controller_class,
        template: 'health_thrive_assessment/assessments/pdf',
        layout: layout,
        user: @user,
        assigns: view_assigns,
      )
      header_html = PdfGenerator.html(
        controller: controller_class,
        partial: 'health_thrive_assessment/assessments/pdf_header',
        user: @user,
        assigns: view_assigns,
      )
      footer_html = PdfGenerator.html(
        controller: controller_class,
        partial: 'health_thrive_assessment/assessments/pdf_footer',
        user: @user,
        assigns: view_assigns,
      )
      options = {
        print_background: true,
        prefer_css_page_size: true,
        scale: 1,
        format: 'letter',
        display_header_footer: true,
        header_template: header_html,
        footer_template: footer_html,
        margin: {
          top: '0.8in',
          bottom: '1.2in',
          left: '0.4in',
          right: '0.4in',
        },
      }
      PdfGenerator.render_pdf(body_html, options: options)
    end

    private

    def view_assigns
      {
        assessment: @assessment,
        client: @assessment.patient.client,
        user: @user,
        title: 'THRIVE Screener',
        pdf: true,
      }
    end

    def controller_class
      HealthThriveAssessment::AssessmentsController
    end
  end
end
