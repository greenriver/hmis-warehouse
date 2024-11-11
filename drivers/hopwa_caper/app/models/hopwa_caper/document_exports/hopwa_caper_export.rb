###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::DocumentExports
  class HopwaCaperExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    include HudReports::HudPdfExportConcern

    def generator_url
      hud_reports_hopwa_caper_path(report)
    end

    private def controller_class
      HopwaCaper::PathsController
    end

    private def possible_generator_classes
      [
        HopwaCaper::Generators::Fy2024::Generator,
      ]
    end
  end
end
