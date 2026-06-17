###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
      HudApr::Dq::DqConcern.possible_generator_classes.values
    end
  end
end
