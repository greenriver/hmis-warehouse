###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
      HopwaCaper::BaseController.new.possible_generator_classes.values
    end
  end
end
