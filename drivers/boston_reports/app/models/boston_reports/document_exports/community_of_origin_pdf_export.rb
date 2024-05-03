###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonReports::DocumentExports
  class CommunityOfOriginPdfExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_view_any_reports? && report_class.viewable_by(user)
    end

    protected def report
      @report ||= report_class.new(filter)
    end

    protected def view_assigns
      {
        report: report,
        filter: filter,
        pdf: true,
      }
    end

    def perform
      with_status_progression do
        template_file = (BostonReports::CommunityOfOrigin.report_path_array + ['index_pdf']).join('/')
        layout = 'layouts/pdf_with_map'

        html = PdfGenerator.html(
          controller: controller_class,
          template: template_file,
          layout: layout,
          user: user,
          assigns: view_assigns,
        )
        PdfGenerator.new.perform(
          html: html,
          file_name: "Community of Origin #{DateTime.current.to_fs(:db)}",
        ) do |io|
          self.pdf_file = io
        end
      end
    end

    protected def report_class
      BostonReports::CommunityOfOrigin
    end

    private def controller_class
      BostonReports::WarehouseReports::CommunityOfOriginsController
    end
  end
end
