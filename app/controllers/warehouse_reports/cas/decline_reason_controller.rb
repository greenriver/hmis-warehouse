module WarehouseReports::Cas
  class DeclineReasonController < ApplicationController
    before_action :require_can_view_reports!

    def index
    end
  end
end