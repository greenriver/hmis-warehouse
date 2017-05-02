class ServiceHistoryLogsController < ApplicationController
  before_action :require_can_view_imports!
  def index
    @service = GrdaWarehouse::GenerateServiceHistoryLog.order(started_at: :desc).page(params[:page]).per(25)
  end
end
