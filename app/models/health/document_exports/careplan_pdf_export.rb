###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Health::DocumentExports
  class CareplanPdfExport
    def self.generate(user:, careplan:)
      new(
        user: user,
        careplan: careplan,
      ).generate
    end

    def initialize(user:, careplan:)
      @user = user
      @careplan = careplan
    end

    def generate
      pdfs = []
      pdfs << coversheet_pdf
      pdfs << body_pdf
      pdfs << @careplan.health_file.content if @careplan.health_file.present?

      cha = @careplan.patient.comprehensive_health_assessments.recent.first
      pdfs << cha.health_file.content if cha.present? && cha.health_file.present? && cha.health_file.content_type == 'application/pdf'

      ssm = @careplan.patient.self_sufficiency_matrix_forms.last
      pdfs << ssm.health_file.content if ssm.is_a?(Health::SelfSufficiencyMatrixForm) && ssm.health_file.present?

      PdfGenerator.merge_inline_pdfs(pdfs)
    end

    private

    def coversheet_pdf
      html = PdfGenerator.html(
        controller: controller_class,
        partial: 'health/careplans/pdf_coversheet',
        layout: 'layouts/careplan_pdf',
        user: @user,
        assigns: view_assigns,
      )
      PdfGenerator.render_pdf(
        html,
        options: {
          format: 'Letter',
          print_background: true,
          display_header_footer: false,
          margin: {
            top: '.5in',
            bottom: '.5in',
            left: '.4in',
            right: '.4in',
          },
        },
      )
    end

    def body_pdf
      body_html = PdfGenerator.html(
        controller: controller_class,
        template: 'health/careplans/show',
        layout: 'layouts/careplan_pdf',
        user: @user,
        assigns: view_assigns,
        env: {
          'action_dispatch.request.path_parameters' => {
            controller: 'health/careplans',
            action: 'show',
            client_id: @careplan.patient.client_id,
          },
        },
      )
      header_html = PdfGenerator.html(
        controller: controller_class,
        partial: 'health/careplans/pdf_header',
        user: @user,
        assigns: view_assigns,
      )
      footer_html = PdfGenerator.html(
        controller: controller_class,
        partial: 'health/careplans/pdf_footer',
        user: @user,
        assigns: view_assigns,
      )
      PdfGenerator.render_pdf(
        body_html,
        options: {
          format: 'Letter',
          print_background: true,
          display_header_footer: true,
          header_template: header_html,
          footer_template: footer_html,
          margin: {
            top: '1in',
            bottom: '1in',
            left: '.4in',
            right: '.4in',
          },
        },
      )
    end

    def view_assigns
      {
        careplan: @careplan,
        patient: @careplan.patient,
        client: @careplan.patient.client,
        user: @user,
        pdf: true,
        html: false,
        goal: Health::Goal::Base.new,
        readonly: false,
      }
    end

    def controller_class
      Health::CareplansController
    end
  end
end
