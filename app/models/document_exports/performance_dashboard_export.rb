###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DocumentExports
  class PerformanceDashboardExport < DocumentExport
    def authorized?
      if Rails.env.development?
        true
      else
        raise 'auth not implemented'
      end
    end

    def perform
      with_status_progression do
        report = load_report
        html = render_html(report)
        PdfGenerator.new.perform(html) do |io|
          self.file = io
        end
        save!
      end
    end

    protected

    def render_html(report)
      assigns = {
        report: report,
        pdf: true,
      }
      context = PerformanceDashboards::OverviewController.view_paths
      view = ActionView::Base.new(context, assigns)

      file_path = 'performance_dashboards/overview/index_pdf'
      view.render(file: file_path)
    end

    def load_report
      # FIXME: - tbd
      OpenStruct.new(user_id: user_id)
    end
  end
end
