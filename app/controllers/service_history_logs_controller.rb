###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class ServiceHistoryLogsController < ApplicationController
  before_action :require_can_view_imports!
  def index
    @service = GrdaWarehouse::GenerateServiceHistoryLog.order(started_at: :desc).page(params.permit![:page]).per(25)
  end
end
