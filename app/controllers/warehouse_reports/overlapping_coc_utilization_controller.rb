###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class OverlappingCoCUtilizationController < ApplicationController
    RELEVANT_COC_STATE = ENV.fetch('RELEVANT_COC_STATE') do
      GrdaWarehouse::Shape::CoC.order('random()').limit(1).pluck(:st)
    rescue StandardError
      'UNKNOWN'
    end

    def index
      @cocs = GrdaWarehouse::Shape::CoC.where(st: RELEVANT_COC_STATE).efficient.order('cocname')
      @shapes = GrdaWarehouse::Shape.geo_collection_hash(@cocs)
    end

    def overlap
      @project_types = GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      @cocs = GrdaWarehouse::Shape::CoC.where(st: RELEVANT_COC_STATE).efficient.order('cocname')
      map_data = {}
      GrdaWarehouse::Shape.geo_collection_hash(@cocs)[:features].each do |feature|
        map_data[feature.dig(:properties,:id).to_s] = rand(100)
      end
      render json: { map: map_data, html: render_to_string(partial: 'overlap') }
    end
  end
end
