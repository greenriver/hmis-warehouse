###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::DocumentExports
  class HudCaperExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    include HudReports::HudPdfExportConcern

    def generator_url
      hud_reports_apr_path(report)
    end

    private def controller_class
      HudApr::CapersController
    end

    private def possible_generator_classes
      [
        HudApr::Generators::Caper::Fy2020::Generator,
        HudApr::Generators::Caper::Fy2021::Generator,
        HudApr::Generators::Caper::Fy2023::Generator,
      ]
    end
  end
end
