###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::CeApr
  class CellsController < HudApr::CellsController
    include CeAprConcern

    private def report_type_param
      'ce_apr'
    end

    private def drilldown_presenter_class
      HudApr::CeAprDrilldownPresenter
    end
  end
end
