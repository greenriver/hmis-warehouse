###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::DocumentExports
  class HudAprExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      return true if user.can_view_all_hud_reports?

      user.can_view_hud_reports? && report.present?
    end

    def generator_url
      hud_reports_apr_path(report)
    end

    private def report_scope
      scope = report_class.
        where(report_name: 'Annual Performance Report - FY 2020')
      return scope if user.can_view_all_hud_reports?

      scope.where(user_id: user.id)
    end

    protected def report
      @report ||= report_scope.find_by(id: params['id'])
    end

    protected def view_assigns
      {
        report: report,
        generator: HudApr::Generators::Apr::Fy2020::Generator,
      }
    end

    def perform
      with_status_progression do
        template_file = 'hud_apr/aprs/download'
        PdfGenerator.new.perform(
          html: view.render(file: template_file, layout: 'layouts/hud_report_export'),
          file_name: "HUD APR 2020 #{DateTime.current.to_s(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected def report_class
      HudReports::ReportInstance
    end

    protected def view
      context = HudApr::AprsController.view_paths
      view = HudApr2020ExportTemplate.new(context, view_assigns)
      view.current_user = user
      view
    end

    class HudApr2020ExportTemplate < PdfExportTemplateBase
      # def details_performance_dashboards_overview_index_path(*args)
      #   '#'
      # end
    end
  end
end
