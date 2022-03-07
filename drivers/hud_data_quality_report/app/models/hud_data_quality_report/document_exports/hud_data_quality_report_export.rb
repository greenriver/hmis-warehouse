###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::DocumentExports
  class HudDataQualityReportExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    include HudReports::HudPdfExportConcern

    def generator_url
      hud_reports_dq_path(report)
    end

    private def controller_class
      HudDataQualityReport::DqsController
    end

    private def possible_generator_classes
      [
        HudDataQualityReport::Generators::Fy2020::Generator,
        HudDataQualityReport::Generators::Fy2022::Generator,
      ]
    end
  end
end
