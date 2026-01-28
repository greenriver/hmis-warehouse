###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
      HudApr::CeApr::CeAprConcern.possible_generator_classes.values
    end
  end
end
