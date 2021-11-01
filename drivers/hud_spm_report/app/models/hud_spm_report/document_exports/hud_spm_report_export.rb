###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::DocumentExports
  class HudSpmReportExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    include HudReports::HudPdfExportConcern

    def generator_url
      hud_reports_spm_path(report)
    end

    private def controller_class
      HudSpmReport::SpmsController
    end

    private def possible_generator_classes
      [
        HudSpmReport::Generators::Fy2020::Generator,
      ]
    end
  end
end
