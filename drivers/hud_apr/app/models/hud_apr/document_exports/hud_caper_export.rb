###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
      HudApr::Caper::CaperConcern.possible_generator_classes.values
    end
  end
end
