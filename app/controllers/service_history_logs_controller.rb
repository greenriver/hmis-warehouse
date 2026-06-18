###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ServiceHistoryLogsController < ApplicationController
  before_action :require_can_view_imports!
  def index
    @service = GrdaWarehouse::GenerateServiceHistoryLog.order(started_at: :desc)
    @pagy, @service = pagy(@service)
  end
end
