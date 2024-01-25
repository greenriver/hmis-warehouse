###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::DocumentExports
  class HudDqExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    include HudReports::HudPdfExportConcern

    def generator_url
      hud_reports_dq_path(report)
    end

    private def controller_class
      HudApr::DqsController
    end

    private def possible_generator_classes
      [
        HudApr::Generators::Dq::Fy2024::Generator,
      ]
    end
  end
end
