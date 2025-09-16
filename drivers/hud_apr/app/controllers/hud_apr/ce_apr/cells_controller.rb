###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::CeApr
  class CellsController < HudApr::CellsController
    include CeAprConcern
    before_action :set_report
    before_action :set_question

    def report_param_name
      :ce_apr_id
    end
  end
end
