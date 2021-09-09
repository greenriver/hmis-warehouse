###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::DocumentExports
  class HudCeAprExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    include HudReports::HudPdfExportConcern

    def generator_url
      hud_reports_ce_apr_path(report)
    end

    private def controller_class
      HudApr::CeAprsController
    end

    private def possible_generator_classes
      [
        HudApr::Generators::CeApr::Fy2020::Generator,
        HudApr::Generators::CeApr::Fy2021::Generator,
      ]
    end
  end
end
