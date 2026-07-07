###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Apr
  class CellsController < HudApr::CellsController
    include AprConcern

    private def report_type_param
      'apr'
    end
  end
end
