###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudReports::HudPdfExportConcern
  extend ActiveSupport::Concern

  included do
    def authorized?
      return true if user.can_view_all_hud_reports?

      user.can_view_hud_reports? && report.present?
    end

    private def report_scope
      scope = report_class.
        where(report_name: possible_titles)
      return scope if user.can_view_all_hud_reports?

      scope.where(user_id: user.id)
    end

    protected def report
      @report ||= report_scope.find_by(id: params['id'])
    end

    private def report_generator_class
      possible_generators[report.report_name]
    end

    private def possible_generators
      possible_generator_classes.map do |rg|
        [
          rg.title,
          rg,
        ]
      end.
        to_h.
        freeze
    end

    private def possible_titles
      possible_generators.keys
    end

    protected def view_assigns
      {
        report: report,
        generator: report_generator_class,
      }
    end

    def perform
      with_status_progression do
        template_file = 'hud_reports/download'
        layout = 'layouts/hud_report_export'

        ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
        renderer = controller_class.renderer.new(
          'warden' => PdfGenerator.warden_proxy(user),
        )
        html = renderer.render(
          template_file,
          layout: layout,
          assigns: view_assigns,
          formats: [:html],
        )

        PdfGenerator.new.perform(
          html: html,
          file_name: "#{report_generator_class.file_prefix}-#{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected def report_class
      HudReports::ReportInstance
    end
  end
end
