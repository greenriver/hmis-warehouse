class WarehouseReportsController < ApplicationController
  before_action :require_can_view_reports!
  def index

  end
end
