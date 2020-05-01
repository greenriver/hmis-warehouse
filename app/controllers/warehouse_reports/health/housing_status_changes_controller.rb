###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Health
  class HousingStatusChangesController < ApplicationController
    before_action :require_can_view_aggregate_health!

    def index
      @end_date = (report_params[:end_date] || Date.current).to_date
      @start_date = (report_params[:start_date] || @end_date - 1.year).to_date
      @acos = report_params[:aco]&.select { |id| id.present? }
      @report = WarehouseReport::Health::HousingStatusChanges.new(@start_date, @end_date, @acos, user: current_user)
    end

    def report_params
      return {} unless params[:filter].present?

      params.require(:filter).permit(
        :start_date,
        :end_date,
        aco: [],
      )
    end
  end
end
