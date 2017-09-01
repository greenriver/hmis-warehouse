module WarehouseReports::Health
  class OverviewController < ApplicationController
    before_action :require_can_view_aggregate_health!

    def index
      
    end
  end
end