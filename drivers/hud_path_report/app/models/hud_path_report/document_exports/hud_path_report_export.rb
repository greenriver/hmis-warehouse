###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::DocumentExports
  class HudPathReportExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    include HudReports::HudPdfExportConcern

    def generator_url
      hud_reports_path_path(report)
    end

    private def controller_class
      HudPathReport::PathsController
    end

    private def possible_generator_classes
      [
        HudPathReport::Generators::Fy2020::Generator,
        HudPathReport::Generators::Fy2021::Generator,
      ]
    end
  end
end
