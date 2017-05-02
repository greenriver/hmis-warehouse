class MatchLogsController < ApplicationController
  before_action :require_can_view_imports!
  def index
    @duplicates = GrdaWarehouse::IdentifyDuplicatesLog.order(started_at: :desc).page(params[:page]).per(25)
  end
end
