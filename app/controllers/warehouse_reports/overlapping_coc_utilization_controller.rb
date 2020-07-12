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
      #fake data for testing
      project_types = ([
        'All (Unique Clients)',
        'CA (Coordinated Assessment)',
      ] + GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES.values).map do |type|
        [type, [rand(100), rand(100)]]
      end
      funding_sources = [
        'All (Unique Clients)',
        'State',
        'ESG (Emergency Solutions Grants)'
      ].map do |source|
        [source, [rand(100), rand(100)]]
      end
      cocs = GrdaWarehouse::Shape::CoC.where(st: RELEVANT_COC_STATE).efficient.order('cocname')
      map_data = {}
      GrdaWarehouse::Shape.geo_collection_hash(cocs)[:features].each do |feature|
        map_data[feature.dig(:properties,:id).to_s] = rand(100)
      end
      locals = {
        start_date: params[:start_date],
        end_date: params[:end_date],
        project_types: project_types,
        funding_sources: funding_sources,
      }
      html = render_to_string partial: 'overlap', locals: locals
      render json: { map: map_data, html: html }
    end
  end
end
