###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Apr
  class CellsController < HudApr::CellsController
    include AprConcern
    before_action :set_report
    before_action :set_question

    def report_param_name
      :apr_id
    end
  end
end
