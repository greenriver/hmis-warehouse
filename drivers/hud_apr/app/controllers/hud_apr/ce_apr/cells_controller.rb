###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
  end
end
