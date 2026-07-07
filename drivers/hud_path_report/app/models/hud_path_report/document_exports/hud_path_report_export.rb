###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudPathReport::DocumentExports
  class HudPathReportExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    include HudReports::HudPdfExportConcern

    def generator_url
      hud_reports_path_path(report)
    end

    private def controller_class
      HudPathReport::PathsController
    end

    private def possible_generator_classes
      HudPathReport::BaseController.new.possible_generator_classes.values
    end
  end
end
