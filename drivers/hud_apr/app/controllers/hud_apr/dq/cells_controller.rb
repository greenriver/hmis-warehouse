###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Dq
  class CellsController < HudApr::CellsController
    include DqConcern

    private def report_type_param
      'dq'
    end
  end
end
