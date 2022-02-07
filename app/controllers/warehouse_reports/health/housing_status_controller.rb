###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class HousingStatusController < ApplicationController
    include AjaxModalRails::Controller

    before_action :require_can_view_aggregate_health!

    def index
      @end_date = (report_params[:end_date] || Date.current).to_date
      @acos = report_params[:aco]&.select { |id| id.present? }
      @report = WarehouseReport::Health::HousingStatus.new(@end_date, @acos, user: current_user)
    end

    def details
      @aco_id = detail_params[:aco_id]&.to_i
      @end_date = (detail_params[:end_date] || Date.current).to_date
      @housing_status = detail_params[:housing_status].to_sym
      @report = WarehouseReport::Health::HousingStatus.new(@end_date, [@aco_id], user: current_user)
    end

    def detail_params
      params.permit(:aco_id, :housing_status, :end_date)
    end

    def report_params
      return {} unless params[:filter].present?

      params.require(:filter).permit(
        :start_date,
        :end_date,
        aco: [],
      )
    end

    def to_query(actives)
      {
        client_ids: actives.map(&:first),
        sources: actives.map(&:last),
      }
    end
    helper_method :to_query
  end
end
