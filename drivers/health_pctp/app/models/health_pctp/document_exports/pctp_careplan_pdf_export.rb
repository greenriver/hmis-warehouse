###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HealthPctp::DocumentExports
  class PctpCareplanPdfExport
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
      layout = 'layouts/careplan_pdf'

      coverpage_html = PdfGenerator.html(
        controller: controller_class,
        template: 'health_pctp/careplans/pdf_coverpage',
        layout: layout,
        user: @user,
        assigns: view_assigns,
      )
      html = PdfGenerator.html(
        controller: controller_class,
        template: 'health_pctp/careplans/edit_pdf',
        layout: layout,
        user: @user,
        assigns: view_assigns,
      )
      header_html = PdfGenerator.html(
        controller: controller_class,
        partial: 'health_pctp/careplans/pdf_header',
        user: @user,
        assigns: view_assigns,
      )
      footer_html = PdfGenerator.html(
        controller: controller_class,
        partial: 'health_pctp/careplans/pdf_footer',
        user: @user,
        assigns: view_assigns,
      )

      options_no_header = {
        print_background: true,
        prefer_css_page_size: true,
        scale: 1,
        format: 'tabloid',
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

      pdf = []
      pdf << PdfGenerator.render_pdf(coverpage_html, options: options_no_header)
      pdf << PdfGenerator.render_pdf(html, options: options)
      pdf << @careplan.health_file.content if @careplan.health_file.present?

      PdfGenerator.merge_inline_pdfs(pdf)
    end

    private

    def view_assigns
      {
        careplan: @careplan,
        user: @user,
        title: 'Care Plan / Patient-Centered Treatment Plan',
        pdf: true,
      }
    end

    def controller_class
      HealthPctp::CareplansController
    end
  end
end
