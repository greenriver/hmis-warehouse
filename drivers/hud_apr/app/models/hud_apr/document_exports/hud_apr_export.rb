###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::DocumentExports
  class HudAprExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    include HudApr::DocumentExports::ExportShared

    def generator_url
      hud_reports_apr_path(report)
    end

    private def controller_class
      HudApr::AprsController
    end

    private def possible_generator_classes
      [
        HudApr::Generators::Apr::Fy2020::Generator,
        HudApr::Generators::Apr::Fy2021::Generator,
      ]
    end
  end
end
