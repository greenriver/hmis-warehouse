###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class OverlappingCoCUtilizationController < ApplicationController
    include WarehouseReportAuthorization
    RELEVANT_COC_STATE = ENV.fetch('RELEVANT_COC_STATE') do
      GrdaWarehouse::Shape::CoC.order(Arel.sql('random()')).limit(1).pluck(:st)
    rescue StandardError
      'UNKNOWN'
    end

    def index
      @end_date = (Date.current - 1.years).end_of_year
      @start_date = @end_date.beginning_of_year
      @cocs = GrdaWarehouse::Shape::CoC.where(st: RELEVANT_COC_STATE).efficient.order('cocname')
      @shapes = GrdaWarehouse::Shape.geo_collection_hash(@cocs)
    end

    def report_params
      params.require(:compare).permit(:coc1, :coc2, :start_date, :end_date)
    end

    def overlap
      coc1 = GrdaWarehouse::Shape::CoC.find(report_params.require(:coc1))
      coc2 = GrdaWarehouse::Shape::CoC.find(report_params.require(:coc2))
      start_date = report_params.require(:start_date)
      end_date = report_params.require(:end_date)
      p_type_report = WarehouseReport::OverlappingCocByProjectType.new(
        coc_code_1: coc1.cocnum,
        coc_code_2: coc2.cocnum,
        start_date: start_date,
        end_date: end_date,
      )
      project_types = p_type_report.for_chart
      funding_sources = WarehouseReport::OverlappingCocByFundingSource.new(
        coc_code_1: coc1.cocnum,
        coc_code_2: coc2.cocnum,
        start_date: start_date,
        end_date: end_date,
      ).for_chart

      ###
      # fake data for testing
      # project_types = ([
      #   'CA (Coordinated Assessment)',
      # ] + GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES.values).map do |type|
      #   [type, [rand(100), rand(100)]]
      # end
      # project_types << ['All Program Types (Unique Clients)', [150, 175]]
      # funding_sources = [
      #   'State',
      #   'ESG (Emergency Solutions Grants)',
      # ].map do |source|
      #   [source, [rand(100), rand(100)]]
      # end
      # funding_sources << ['All Funding Sources (Unique Clients)', [150, 175]]
      cocs = GrdaWarehouse::Shape::CoC.where(st: RELEVANT_COC_STATE).efficient.order('cocname')
      map_data = {}
      GrdaWarehouse::Shape.geo_collection_hash(cocs)[:features].each do |feature|
        map_data[feature.dig(:properties, :id).to_s] = rand(225)
      end
      ###
      locals = {
        start_date: params.dig(:compare, :start_date),
        end_date: params.dig(:compare, :end_date),
        project_types: project_types,
        funding_sources: funding_sources,
        overlapping_client_count: p_type_report.all_overlapping_clients,
      }
      html = render_to_string partial: 'overlap', locals: locals
      render json: { map: map_data, html: html }
    end
  end
end
