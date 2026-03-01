###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Caper
  class CellsController < HudApr::CellsController
    include CaperConcern

    private def report_type_param
      'caper'
    end
  end
end
