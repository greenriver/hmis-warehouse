class DashboardsController < ApplicationController
  before_action :require_can_view_censuses!
  def index
    
  end
end