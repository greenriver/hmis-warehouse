###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::DocumentExports::ExportShared
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
      end.to_h.freeze
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
        PdfGenerator.new.perform(
          html: view.render(file: template_file, layout: 'layouts/hud_report_export'),
          file_name: "#{report_generator_class.file_prefix}-#{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected def report_class
      HudReports::ReportInstance
    end

    protected def view
      context = controller_class.view_paths
      view = PdfExportTemplateBase.new(context, view_assigns)
      view.current_user = user
      view
    end
  end
end
