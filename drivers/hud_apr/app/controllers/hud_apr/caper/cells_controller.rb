###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Caper
  class CellsController < HudApr::CellsController
    include CaperConcern
    before_action :set_report
    before_action :set_question

    def report_param_name
      :caper_id
    end
  end
end
