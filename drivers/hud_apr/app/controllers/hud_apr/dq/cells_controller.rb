###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Dq
  class CellsController < HudApr::CellsController
    include DqConcern
    before_action :generator
    before_action :set_report
    before_action :set_question

    def report_param_name
      :dq_id
    end
  end
end
