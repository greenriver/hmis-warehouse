###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ServiceHistoryLogsController < ApplicationController
  before_action :require_can_view_imports!
  def index
    @pagy, @service = pagy(GrdaWarehouse::GenerateServiceHistoryLog.order(started_at: :desc))
  end
end
